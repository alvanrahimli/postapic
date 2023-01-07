import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class Post {
  const Post(this.id, this.title, this.imageUrl, this.createdAt, this.author);

  final int id;
  final String title;
  final String imageUrl;
  final DateTime createdAt;
  final User author;

  Map<String, dynamic> toJson() => _$PostToJson(this);
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@JsonSerializable()
class User {
  const User(this.id, this.userName);

  final int id;
  final String userName;

  Map<String, dynamic> toJson() => _$UserToJson(this);
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
