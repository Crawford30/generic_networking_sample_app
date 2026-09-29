import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_networking/generic_networking.dart';
import 'package:generic_networking_sample/features/posts/data/posts_repository.dart';
import 'package:generic_networking_sample/features/posts/presentation/posts_page.dart';
import 'package:generic_networking_sample/features/posts/presentation/posts_providers.dart';

import 'fakes.dart';

void main() {
  late FakePostsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakePostsRepository();
    container = ProviderContainer.test(
      overrides: [postsRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
    );
  });

  test('delete removes the post only after the server succeeds', () async {
    await container.read(postsProvider.future);

    repository.failWith = ApiException(type: NetworkErrorType.server, message: 'boom');
    await expectLater(
      container.read(postsProvider.notifier).delete(fakePost(1)),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(postsProvider).value, hasLength(3));

    repository.failWith = null;
    await container.read(postsProvider.notifier).delete(fakePost(1));
    expect(container.read(postsProvider).value!.map((p) => p.id), [2, 3]);
  });

  test('renaming in detail also updates the list', () async {
    await container.read(postsProvider.future);
    final sub = container.listen(postDetailProvider(2), (_, _) {});
    await container.read(postDetailProvider(2).future);

    await container.read(postDetailProvider(2).notifier).rename('Renamed');

    expect(sub.read().value!.post.title, 'Renamed');
    expect(container.read(postsProvider).value![1].title, 'Renamed');
  });

  test('detail for a missing id errors with the ApiException, not ParallelWaitError', () async {
    final sub = container.listen(postDetailProvider(999), (_, _) {});
    await expectLater(container.read(postDetailProvider(999).future), throwsA(isA<ApiException>()));
    expect(sub.read().error, isA<ApiException>());
  });

  test('create validates locally and adds the new post to the list', () async {
    await container.read(postsProvider.future);
    final sub = container.listen(createPostProvider, (_, _) {});
    final notifier = container.read(createPostProvider.notifier);

    expect(await notifier.submit(title: '', body: 'short'), isNull);
    expect(sub.read().fieldErrors.keys, containsAll(['title', 'body']));

    final created = await notifier.submit(title: 'Hello', body: 'A long enough body');
    expect(created!.id, 101);
    expect(container.read(postsProvider).value!.first.id, 101);
  });

  testWidgets('PostsPage renders posts from the overridden repository', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [postsRepositoryProvider.overrideWithValue(FakePostsRepository())],
      child: const MaterialApp(home: PostsPage()),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Title 3'), findsOneWidget);
  });
}
