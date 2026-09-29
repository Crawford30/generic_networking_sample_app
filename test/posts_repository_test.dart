import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_networking/generic_networking.dart';
import 'package:generic_networking_sample/features/posts/data/models.dart';
import 'package:generic_networking_sample/features/posts/data/posts_repository.dart';

import 'fakes.dart';

void main() {
  late FakeAdapter adapter;
  late PostsRepository repository;

  void serve(ResponseBody Function(RequestOptions o) respond) {
    adapter = FakeAdapter(respond);
    repository = PostsRepositoryImpl(DioNetworkingClient(
      config: const NetworkConfig(baseUrl: 'https://api.test/', enableLogging: false),
      dio: Dio()..httpClientAdapter = adapter,
    ));
  }

  test('posts() GETs /posts, drops null query params and parses the list', () async {
    serve((_) => json([
          {'id': 1, 'userId': 7, 'title': 'a', 'body': 'b'},
        ]));

    final posts = await repository.posts();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.uri.toString(), 'https://api.test/posts');
    expect(posts.single.userId, 7);
  });

  test('create() POSTs the JSON body', () async {
    serve((_) => json({'id': 101, 'userId': 1, 'title': 't', 'body': 'b'}, status: 201));

    final created = await repository.create(const NewPost(userId: 1, title: 't', body: 'b'));

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, isNotNull);
    expect(created.id, 101);
  });

  test('a 404 surfaces as ApiException(notFound)', () async {
    serve((_) => json({}, status: 404));

    await expectLater(
      repository.post(999999),
      throwsA(isA<ApiException>().having((e) => e.type, 'type', NetworkErrorType.notFound)),
    );
  });
}
