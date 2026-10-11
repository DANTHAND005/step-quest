import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

/// Add friends by username, accept requests, see your friends.
class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key, required this.api});

  final Api api;

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final _username = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a server action, shows the result, and reloads the list if it worked.
  Future<bool> _run(Future<void> Function() action, String success, Future<void> Function() reload) async {
    try {
      await action();
      if (!mounted) return false;
      _toast(success);
      await reload();
      return true;
    } on ApiError catch (e) {
      if (mounted) _toast(e.message);
      return false;
    }
  }

  Future<void> _add(Future<void> Function() reload) async {
    final name = _username.text.trim();
    if (name.isEmpty) return;
    setState(() => _sending = true);
    final ok = await _run(() => widget.api.requestFriend(name), 'Request sent to $name', reload);
    if (!mounted) return;
    if (ok) _username.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return LoadView<Map<String, dynamic>>(
      load: widget.api.friends,
      builder: (context, data, reload) {
        final text = Theme.of(context).textTheme;
        final friends = data['friends'] as List<dynamic>;
        final requests = data['requests'] as List<dynamic>;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _username,
              autocorrect: false,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _add(reload),
              decoration: InputDecoration(
                labelText: 'Add a friend by username',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Send request',
                  onPressed: _sending ? null : () => _add(reload),
                ),
              ),
            ),
            if (requests.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Friend requests', style: text.titleMedium),
              for (final r in requests)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Avatar(r['username'] as String),
                  title: Text(r['username'] as String),
                  trailing: FilledButton.tonal(
                    onPressed: () => _run(
                      () => widget.api.acceptFriend(r['id'] as int),
                      'You and ${r['username']} are now friends',
                      reload,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            Text('Friends', style: text.titleMedium),
            if (friends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No friends yet. Add someone by their username above.', style: text.bodyMedium),
              ),
            for (final f in friends)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Avatar(f['username'] as String),
                title: Text(f['username'] as String),
              ),
          ],
        );
      },
    );
  }
}
