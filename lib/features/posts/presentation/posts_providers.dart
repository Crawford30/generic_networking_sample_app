import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generic_networking/generic_networking.dart';

import '../data/models.dart';
import '../data/posts_repository.dart';

// ---- List --------------------------------------------------------------------

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<Post>>(PostsNotifier.new);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  PostsRepository get _repository => ref.read(postsRepositoryProvider);

  @override
  Future<List<Post>> build() => ref.watch(postsRepositoryProvider).posts();

  /// Pull-to-refresh: Riverpod keeps the current list on screen while
  /// reloading, and keeps it if the reload fails.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on ApiException {
      // Surfaced through `state`.
    }
  }

  /// Throws [ApiException] so the caller can show a snackbar; the list is
  /// only changed once the server confirms.
  Future<void> delete(Post post) async {
    await _repository.delete(post.id);
    _update((posts) => posts.where((p) => p.id != post.id).toList());
  }

  void add(Post post) => _update((posts) => [post, ...posts]);

  void replace(Post post) =>
      _update((posts) => [for (final p in posts) p.id == post.id ? post : p]);

  void _update(List<Post> Function(List<Post> posts) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}

// ---- Detail ------------------------------------------------------------------

typedef PostDetail = ({Post post, List<Comment> comments});

final postDetailProvider =
    AsyncNotifierProvider.autoDispose.family<PostDetailNotifier, PostDetail, int>(
  PostDetailNotifier.new,
);

class PostDetailNotifier extends AsyncNotifier<PostDetail> {
  PostDetailNotifier(this.postId);

  final int postId;

  /// Post and comments are fetched in parallel. `Future.wait` rethrows the
  /// first [ApiException] as-is (a record's `.wait` would wrap it).
  @override
  Future<PostDetail> build() async {
    final repository = ref.watch(postsRepositoryProvider);
    final post = repository.post(postId);
    final comments = repository.comments(postId);
    await Future.wait([post, comments]);
    return (post: await post, comments: await comments);
  }

  /// PATCH the title, then update this screen and the list behind it.
  Future<void> rename(String title) async {
    final updated = await ref.read(postsRepositoryProvider).rename(postId, title);
    if (!ref.mounted) return;
    state = AsyncData((post: updated, comments: state.requireValue.comments));
    ref.read(postsProvider.notifier).replace(updated);
  }
}

// ---- Create ------------------------------------------------------------------

class CreatePostState {
  const CreatePostState({this.submitting = false, this.fieldErrors = const {}, this.error});

  final bool submitting;
  final Map<String, String> fieldErrors;
  final String? error;
}

final createPostProvider =
    NotifierProvider.autoDispose<CreatePostNotifier, CreatePostState>(CreatePostNotifier.new);

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  /// Validates locally first; server-side field errors (400/422) come back
  /// through [ApiException.fieldErrors]. Returns the created post, or null.
  Future<Post?> submit({required String title, required String body}) async {
    final errors = {
      if (title.trim().isEmpty) 'title': 'Title is required',
      if (body.trim().length < 10) 'body': 'Write at least 10 characters',
    };
    if (errors.isNotEmpty) {
      state = CreatePostState(fieldErrors: errors);
      return null;
    }

    state = const CreatePostState(submitting: true);
    try {
      final post = await ref
          .read(postsRepositoryProvider)
          .create(NewPost(userId: 1, title: title.trim(), body: body.trim()));
      ref.read(postsProvider.notifier).add(post);
      if (ref.mounted) state = const CreatePostState();
      return post;
    } on ApiException catch (e) {
      if (ref.mounted) state = CreatePostState(fieldErrors: e.fieldErrors, error: e.message);
      return null;
    }
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    state = CreatePostState(
      fieldErrors: {...state.fieldErrors}..remove(field),
      error: state.error,
    );
  }
}
