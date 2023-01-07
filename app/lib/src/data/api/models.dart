import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class Post {
  const Post(this.id, this.title, this.image, this.createdAt, this.author);

  final int id;
  final String title;
  final ImageRef image;
  final DateTime createdAt;
  final User author;

  Map<String, dynamic> toJson() => _$PostToJson(this);
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@JsonSerializable()
class ImageRef {
  const ImageRef(this.url, this.width, this.height);

  final String url;
  final int width;
  final int height;

  Map<String, dynamic> toJson() => _$ImageRefToJson(this);
  factory ImageRef.fromJson(Map<String, dynamic> json) =>
      _$ImageRefFromJson(json);
}

@JsonSerializable()
class User {
  const User(this.id, this.userName);

  final int id;
  final String userName;

  Map<String, dynamic> toJson() => _$UserToJson(this);
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
