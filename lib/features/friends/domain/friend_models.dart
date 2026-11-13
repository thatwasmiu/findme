import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_models.freezed.dart';
part 'friend_models.g.dart';

@freezed
abstract class Me with _$Me {
  const factory Me({
    required String name,
    required String friendCode,

    /// Look Back media id of your avatar, when you set one.
    String? avatar,

    /// The original (legacy) account, which cannot be deleted.
    @Default(false) bool owner,
  }) = _Me;
  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);
}

@freezed
abstract class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String name,
    required String since,
    String? lastTs,
    String? avatar,
  }) = _Friend;
  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}

/// A friend request, in or out.
@freezed
abstract class Pending with _$Pending {
  const factory Pending({
    required String id,
    required String name,
    required String at,
  }) = _Pending;
  factory Pending.fromJson(Map<String, dynamic> json) =>
      _$PendingFromJson(json);
}

@freezed
abstract class Relations with _$Relations {
  const factory Relations({
    @Default(<Friend>[]) List<Friend> friends,
    @Default(<Pending>[]) List<Pending> incoming,
    @Default(<Pending>[]) List<Pending> outgoing,
  }) = _Relations;
  factory Relations.fromJson(Map<String, dynamic> json) =>
      _$RelationsFromJson(json);

  static const empty = Relations();
}
