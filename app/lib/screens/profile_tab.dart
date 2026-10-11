import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../widgets.dart';
import 'login_screen.dart';

/// Your account, the token for the iPhone Shortcut, and log out.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.api});

  final Api api;

  Future<void> _logOut(BuildContext context) async {
    await api.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(api: api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = api.username ?? '';
    final token = api.token ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Avatar(name),
          title: Text(name, style: text.titleLarge),
          subtitle: Text('Connected to ${api.server}'),
        ),
        const SizedBox(height: 24),
        Text('iPhone Shortcut', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'The Shortcut sends your Apple Health steps to the server. '
          'Put this token in its Authorization header. '
          "For the address, use your PC's Tailscale IP with port 8000, not localhost. "
          'Full steps are in shortcut/README.md.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: const Text('Your token'),
            subtitle: SelectableText(token, style: const TextStyle(fontFamily: 'monospace')),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy token',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied')),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => _logOut(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}
