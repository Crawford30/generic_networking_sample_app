import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generic_networking/generic_networking.dart';

import 'core/network/network_providers.dart';
import 'features/posts/presentation/posts_page.dart';

void main() {
  runApp(
    const ProviderScope(
      retry: retryTransientErrors,
      child: SampleApp(),
    ),
  );
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generic Networking Sample',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      builder: (context, child) => OfflineBanner(child: child!),
      home: const PostsPage(),
    );
  }
}
