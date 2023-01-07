// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      json['id'] as int,
      json['title'] as String,
      ImageRef.fromJson(json['image'] as Map<String, dynamic>),
      DateTime.parse(json['createdAt'] as String),
      User.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
      'createdAt': instance.createdAt.toIso8601String(),
      'author': instance.author,
    };

ImageRef _$ImageRefFromJson(Map<String, dynamic> json) => ImageRef(
      json['url'] as String,
      json['width'] as int,
      json['height'] as int,
    );

Map<String, dynamic> _$ImageRefToJson(ImageRef instance) => <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      json['id'] as int,
      json['userName'] as String,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'userName': instance.userName,
    };
