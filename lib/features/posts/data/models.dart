import 'package:generic_networking/generic_networking.dart';

class Post {
  const Post({required this.id, required this.userId, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        userId: json['userId'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
      );

  final int id;
  final int userId;
  final String title;
  final String body;
}

class Comment {
  const Comment({required this.id, required this.name, required this.email, required this.body});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        body: json['body'] as String,
      );

  final int id;
  final String name;
  final String email;
  final String body;
}

/// Request body for creating a post.
class NewPost implements JsonSerializable {
  const NewPost({required this.userId, required this.title, required this.body});

  final int userId;
  final String title;
  final String body;

  @override
  Map<String, dynamic> toJson() => {'userId': userId, 'title': title, 'body': body};
}
