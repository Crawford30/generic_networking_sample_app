import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../data/models.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';
import 'posts_providers.dart';

/// A post id JSONPlaceholder does not have, to show how a 404 surfaces.
const _missingPostId = 999999;

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            tooltip: 'Open a missing post (404)',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _openDetail(context, _missingPostId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreatePostPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
      // Show data whenever we have it (even while refreshing or after a
      // failed refresh); fall back to the error, then the spinner.
      body: switch (posts) {
        AsyncValue(:final value?) => RefreshIndicator(
            onRefresh: () => ref.read(postsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: value.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _PostTile(post: value[i]),
            ),
          ),
        AsyncValue(:final error?) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(postsProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PostTile extends ConsumerWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(post.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline),
      ),
      // Only remove the row once the DELETE succeeds.
      confirmDismiss: (_) async {
        try {
          await ref.read(postsProvider.notifier).delete(post);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMessage(e))));
          }
          return false;
        }
      },
      child: ListTile(
        leading: CircleAvatar(child: Text('${post.id}')),
        title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _openDetail(context, post.id),
      ),
    );
  }
}

void _openDetail(BuildContext context, int id) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: id)),
    );
