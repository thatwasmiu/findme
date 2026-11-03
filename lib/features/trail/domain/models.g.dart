// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Stop _$StopFromJson(Map<String, dynamic> json) => _Stop(
  lon: (json['lon'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
  start: json['start'] as String,
  end: json['end'] as String,
  seconds: (json['seconds'] as num).toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$StopToJson(_Stop instance) => <String, dynamic>{
  'lon': instance.lon,
  'lat': instance.lat,
  'start': instance.start,
  'end': instance.end,
  'seconds': instance.seconds,
  'name': instance.name,
};

_LastPoint _$LastPointFromJson(Map<String, dynamic> json) => _LastPoint(
  lon: (json['lon'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
  ts: json['ts'] as String,
);

Map<String, dynamic> _$LastPointToJson(_LastPoint instance) =>
    <String, dynamic>{
      'lon': instance.lon,
      'lat': instance.lat,
      'ts': instance.ts,
    };
