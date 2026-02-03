import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.eco, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Lily Notes',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Privacy Policy',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Lily Notes is a fully offline, local-only note-taking app. '
            'All your data is stored exclusively on your device using local storage.\n\n'
            '• No data is collected or transmitted over the network.\n'
            '• No analytics, tracking, or telemetry of any kind.\n'
            '• No accounts, sign-ups, or cloud sync.\n'
            '• No third-party services receive your data.\n\n'
            'Uninstalling the app will permanently delete all stored data.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
