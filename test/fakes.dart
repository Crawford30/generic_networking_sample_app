import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:generic_networking/generic_networking.dart';
import 'package:generic_networking_sample/features/posts/data/models.dart';
import 'package:generic_networking_sample/features/posts/data/posts_repository.dart';

/// Answers HTTP calls in memory so the real [DioNetworkingClient] can be tested.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object? data, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

Post fakePost(int id, [String title = 'Title']) =>
    Post(id: id, userId: 1, title: '$title $id', body: 'Body of post $id');

/// In-memory repository for provider and widget tests.
class FakePostsRepository implements PostsRepository {
  FakePostsRepository({List<Post>? posts}) : store = posts ?? [fakePost(1), fakePost(2), fakePost(3)];

  final List<Post> store;
  Object? failWith;

  Future<T> _answer<T>(T Function() value) async {
    if (failWith case final error?) throw error;
    return value();
  }

  @override
  Future<List<Post>> posts({int? userId}) => _answer(() => List.of(store));

  @override
  Future<Post> post(int id) => _answer(() => store.firstWhere((p) => p.id == id,
      orElse: () => throw ApiException.fromResponse(statusCode: 404, data: const {})));

  @override
  Future<List<Comment>> comments(int postId) => _answer(() => const []);

  @override
  Future<Post> create(NewPost p) =>
      _answer(() => Post(id: 101, userId: p.userId, title: p.title, body: p.body));

  @override
  Future<Post> rename(int id, String title) => _answer(() {
        final p = store.firstWhere((p) => p.id == id);
        return Post(id: id, userId: p.userId, title: title, body: p.body);
      });

  @override
  Future<void> delete(int id) => _answer(() => store.removeWhere((p) => p.id == id));
}
