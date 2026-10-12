import 'dart:async';

import 'package:flutter/material.dart';

/// 1234567 -> "1,234,567"
String formatNumber(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Circle with the first letter of a name.
class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(child: Text(name.isEmpty ? '?' : name[0].toUpperCase()));
  }
}

/// Loads data once, shows a spinner while waiting and an error with a
/// "Try again" button if it fails. Pull down to reload.
///
/// Every tab uses this, so a new screen only needs a [load] and a [builder].
class LoadView<T> extends StatefulWidget {
  const LoadView({super.key, required this.load, required this.builder, this.autoRefresh});

  final Future<T> Function() load;

  /// Reload quietly on this interval, e.g. so new steps show up on their own.
  final Duration? autoRefresh;

  /// Build the screen from the data. Call `reload` after changing something.
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<LoadView<T>> createState() => _LoadViewState<T>();
}

class _LoadViewState<T> extends State<LoadView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
    final every = widget.autoRefresh;
    if (every != null) _timer = Timer.periodic(every, (_) => _reload(quiet: true));
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reload({bool quiet = false}) async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      // Already showing data? Keep it and just mention the problem.
      if (_data != null && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _reload();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: widget.builder(context, _data as T, _reload),
    );
  }
}
