import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/widgets/error_view.dart';
import 'posts_providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = postDetailProvider(postId);
    final detail = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Post $postId'),
        actions: [
          if (detail.hasValue)
            IconButton(
              tooltip: 'Rename',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _rename(context, ref, detail.requireValue.post.title),
            ),
        ],
      ),
      body: switch (detail) {
        AsyncValue(:final value?) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(value.post.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(value.post.body),
              const SizedBox(height: 24),
              Text('Comments (${value.comments.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              for (final c in value.comments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name),
                  subtitle: Text('${c.email}\n${c.body}'),
                  isThreeLine: true,
                ),
            ],
          ),
        AsyncValue(:final error?) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(provider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String current) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: current),
    );
    if (title == null || title.trim().isEmpty) return;

    try {
      await ref.read(postDetailProvider(postId).notifier).rename(title.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Title updated (PATCH)')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
      }
    }
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename post'),
      content: TextField(controller: _controller, autofocus: true, maxLines: null),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
