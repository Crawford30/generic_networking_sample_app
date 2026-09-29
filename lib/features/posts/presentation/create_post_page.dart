import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'posts_providers.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final post = await ref
        .read(createPostProvider.notifier)
        .submit(title: _title.text, body: _body.text);
    if (post != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created post #${post.id} (POST)')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostProvider);
    final notifier = ref.read(createPostProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('New post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            enabled: !state.submitting,
            textInputAction: TextInputAction.next,
            onChanged: (_) => notifier.clearFieldError('title'),
            decoration: InputDecoration(
              labelText: 'Title',
              errorText: state.fieldErrors['title'],
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _body,
            enabled: !state.submitting,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => notifier.clearFieldError('body'),
            decoration: InputDecoration(
              labelText: 'Body',
              errorText: state.fieldErrors['body'],
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.submitting ? null : _submit,
            child: state.submitting
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
    );
  }
}
