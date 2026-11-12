// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Share _$ShareFromJson(Map<String, dynamic> json) => _Share(
  id: json['id'] as String,
  label: json['label'] as String,
  createdAt: json['createdAt'] as String,
  expiresAt: json['expiresAt'] as String,
  route: json['route'] as bool? ?? false,
  routeFrom: json['routeFrom'] as String?,
  bag: json['bag'] as bool? ?? false,
  pics: json['pics'] as bool? ?? false,
);

Map<String, dynamic> _$ShareToJson(_Share instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'createdAt': instance.createdAt,
  'expiresAt': instance.expiresAt,
  'route': instance.route,
  'routeFrom': instance.routeFrom,
  'bag': instance.bag,
  'pics': instance.pics,
};
