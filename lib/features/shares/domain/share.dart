import 'package:freezed_annotation/freezed_annotation.dart';

part 'share.freezed.dart';
part 'share.g.dart';

/// A share link as the owner sees it (the id IS the secret in the URL).
@freezed
abstract class Share with _$Share {
  const factory Share({
    required String id,
    required String label,
    required String createdAt,
    required String expiresAt,
    @Default(false) bool route,

    /// First local day of the shared route ("YYYY-MM-DD"); null = today only.
    String? routeFrom,

    /// Anyone holding the link can open the bag.
    @Default(false) bool bag,
  }) = _Share;
  const Share._();

  factory Share.fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);

  bool expiredAt(DateTime now) => !DateTime.parse(expiresAt).isAfter(now);
}
