import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generic_networking/generic_networking.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_providers.dart';
import 'models.dart';

/// What the UI layer depends on. Swap the implementation for a fake in tests.
abstract interface class PostsRepository {
  Future<List<Post>> posts({int? userId});
  Future<Post> post(int id);
  Future<List<Comment>> comments(int postId);
  Future<Post> create(NewPost post);
  Future<Post> rename(int id, String title);
  Future<void> delete(int id);
}

class PostsRepositoryImpl implements PostsRepository {
  PostsRepositoryImpl(this._client);

  final NetworkingClient _client;

  @override
  Future<List<Post>> posts({int? userId}) => _client.getAPI(
        ApiEndpoints.posts,
        Deserializer.list(Post.fromJson),
        queryParameters: {'userId': userId},
      );

  @override
  Future<Post> post(int id) =>
      _client.getAPI(ApiEndpoints.post(id), Deserializer.object(Post.fromJson));

  @override
  Future<List<Comment>> comments(int postId) =>
      _client.getAPI(ApiEndpoints.postComments(postId), Deserializer.list(Comment.fromJson));

  @override
  Future<Post> create(NewPost post) =>
      _client.postAPI(ApiEndpoints.posts, Deserializer.object(Post.fromJson), body: post);

  @override
  Future<Post> rename(int id, String title) => _client.patchAPI(
        ApiEndpoints.post(id),
        Deserializer.object(Post.fromJson),
        body: {'title': title},
      );

  @override
  Future<void> delete(int id) => _client.deleteAPI(ApiEndpoints.post(id));
}

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostsRepositoryImpl(ref.watch(networkingClientProvider)),
);
