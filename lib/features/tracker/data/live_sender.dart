import 'dart:async';
import 'dart:math';

import 'package:findme/core/config/app_config.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:findme/features/tracker/domain/live_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// One connection to the live broker: `MqttLiveLink` on the phone, a fake in tests.
abstract interface class LiveLink {
  /// false: refused or unreachable.
  Future<bool> connect({required String clientId, required String password});

  /// Retained, QoS 0. Throws when not connected.
  void publish(String topic, String payload);

  /// Never followed by [onDrop].
  void disconnect();

  /// The broker or the network closed an open connection.
  abstract void Function()? onDrop;
}

/// MQTT 3.1.1 over WebSockets (travel-heatmap guide chapter 23). Username `findme` (ignored by the broker, but 3.1.1
/// refuses a password without one). No logging: the client would print the token and the topic.
class MqttLiveLink implements LiveLink {
  MqttLiveLink(this.url);

  final String url;
  MqttServerClient? _c;

  @override
  void Function()? onDrop;

  @override
  Future<bool> connect({
    required String clientId,
    required String password,
  }) async {
    disconnect();
    final c =
        MqttServerClient.withPort(
            url,
            clientId,
            Uri.parse(url).port,
            maxConnectionAttempts: 1,
          )
          ..useWebSocket = true
          ..websocketProtocols = MqttClientConstants.protocolsSingleDefault
          ..keepAlivePeriod =
              60 // nginx keeps an idle socket 300 s
          ..connectTimeoutPeriod = 10000
          ..autoReconnect = false
          ..setProtocolV311()
          ..logging(on: false);
    _c = c;
    var ready = false;
    c.onDisconnected = () {
      if (ready && identical(_c, c)) {
        _c = null;
        onDrop?.call();
      }
    };
    try {
      ready =
          (await c.connect('findme', password))?.state ==
          MqttConnectionState.connected;
    } on Object {
      ready = false;
    }
    if (ready && identical(_c, c)) return true;
    ready = false;
    if (identical(_c, c)) _c = null;
    _quietly(
      c.disconnect,
    ); // refused, failed, or disconnect() came while connecting
    return false;
  }

  @override
  void publish(String topic, String payload) {
    final c = _c;
    if (c == null) throw StateError('not connected');
    final b = MqttClientPayloadBuilder()..addUTF8String(payload);
    c.publishMessage(topic, MqttQos.atMostOnce, b.payload!, retain: true);
  }

  @override
  void disconnect() {
    final c = _c;
    _c = null;
    if (c != null) _quietly(c.disconnect);
  }

  static void _quietly(void Function() f) {
    try {
      f();
    } on Object {
      // already closed
    }
  }
}

/// Live positions while the tracker records: each fix that says something new goes to `live/<account id>` at once
/// (at most one a second), the newest again after every reconnect. [stop] clears the retained position. A side
/// channel: nothing here throws into the tracker, and `/ingest` never waits on it.
class LiveSender {
  LiveSender(
    this._link,
    this._token, {
    DateTime Function()? now,
    Random? random,
  }) : _now = now ?? DateTime.now,
       _suffix = List.generate(
         4,
         (_) => (random ?? Random.secure())
             .nextInt(256)
             .toRadixString(16)
             .padLeft(2, '0'),
       ).join() {
    _link.onDrop = _dropped;
  }

  final LiveLink _link;
  final Future<IngestToken?> Function() _token;
  final DateTime Function() _now;
  final String _suffix;

  static const _first = Duration(seconds: 2);
  static const _most = Duration(seconds: 60);
  static const _gap = Duration(seconds: 1);

  bool _running = false;
  int _gen = 0;
  bool _up = false;
  DateTime? _upSince;
  Duration _wait = _first;
  Timer? _retry;
  Timer? _soon;

  /// Waiting to go (connecting, or inside the one-second gap); the newest wins.
  Fix? _pending;
  Fix? _published;
  DateTime? _sentAt;

  /// From the last good connect, for the clear in [stop] (the store may be wiped by then).
  ({String clientId, String password, String id})? _who;

  void start() {
    if (_running) return;
    _running = true;
    _gen++;
    _wait = _first;
    unawaited(_connect(_gen));
  }

  void onFix(Fix f) {
    if (!_running || !worthPublishing(f, _published)) return;
    _pending = f;
    _send();
  }

  void _send() {
    final f = _pending;
    final who = _who;
    if (!_up || f == null || who == null || _soon != null) return;
    final sent = _sentAt;
    if (sent != null) {
      final left = _gap - _now().difference(sent);
      if (left > Duration.zero) {
        _soon = Timer(left, () {
          _soon = null;
          _send();
        });
        return;
      }
    }
    try {
      _link.publish(liveTopic(who.id), livePayload(f));
    } on Object {
      return; // dropped: onDrop reconnects and sends it then
    }
    _published = f;
    _pending = null;
    _sentAt = _now();
  }

  Future<void> _connect(int gen) async {
    _retry = null;
    IngestToken? t;
    try {
      t = await _token();
    } on Object {
      t = null; // Keychain locked: later
    }
    if (gen != _gen) return;
    if (t == null) return _later();
    final who = (
      clientId: '${t.sub}/phone-$_suffix',
      password: t.token,
      id: t.sub,
    );
    final ok = await _link.connect(
      clientId: who.clientId,
      password: who.password,
    );
    if (gen != _gen) {
      if (ok) _link.disconnect(); // stopped meanwhile
      return;
    }
    if (!ok) return _later();
    _who = who;
    _up = true;
    _upSince = _now();
    _pending ??=
        _published; // the newest fix again: friends who missed it get it now
    _send();
  }

  void _later() {
    _retry?.cancel();
    final gen = _gen;
    _retry = Timer(_wait, () => unawaited(_connect(gen)));
    final next = _wait * 2;
    _wait = next > _most ? _most : next;
  }

  void _dropped() {
    if (!_running || !_up) return;
    _up = false;
    _soon?.cancel();
    _soon = null;
    final since = _upSince;
    // A connection that lasted resets the wait; one kicked at once (trip not open on the server yet) does not.
    if (since != null && _now().difference(since) >= _most) _wait = _first;
    _later();
  }

  /// Clears `live/<id>` (always allowed by the broker, even after the trip ended), then disconnects. Not connected:
  /// one connect just for that, best effort.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _gen++;
    _retry?.cancel();
    _soon?.cancel();
    _retry = _soon = null;
    _pending = _published = _sentAt = null;
    final who = _who;
    final wasUp = _up;
    _up = false;
    if (who == null) return; // never connected: nothing of ours is retained
    try {
      if (!wasUp &&
          !await _link
              .connect(clientId: who.clientId, password: who.password)
              .timeout(const Duration(seconds: 10), onTimeout: () => false)) {
        return;
      }
      _link.publish(liveTopic(who.id), '');
      await Future<void>.delayed(
        _gap,
      ); // let the clear leave before the socket closes
    } on Object catch (e) {
      debugPrint('live clear failed: ${e.runtimeType}');
    } finally {
      _link.disconnect();
    }
  }
}

/// null when no broker is configured (`MQTT_URL`): the tracker works as before.
final liveSenderProvider = Provider<LiveSender?>((ref) {
  final url = ref.watch(appConfigProvider).mqttUrl;
  if (url == null) return null;
  final store = ref.watch(trackerStoreProvider);
  return LiveSender(MqttLiveLink(url), store.token);
});
