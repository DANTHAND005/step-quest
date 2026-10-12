import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

/// Today's steps, the last 7 days, coins, and progress to the next coins.
class TodayTab extends StatelessWidget {
  const TodayTab({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) {
    return LoadView<Map<String, dynamic>>(
      load: api.me,
      autoRefresh: const Duration(seconds: 5),
      builder: (context, me, reload) {
        final text = Theme.of(context).textTheme;
        final total = me['total'] as int;
        final intoNext = total % 1000;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hi, ${me['username']}', style: text.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Text(
                      formatNumber(me['today'] as int),
                      style: text.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('steps today', style: text.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.calendar_today,
                    label: 'Last 7 days',
                    value: formatNumber(me['week'] as int),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    icon: Icons.monetization_on_outlined,
                    label: 'Coins',
                    value: formatNumber(me['coins'] as int),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatNumber(1000 - intoNext)} steps until your next 10 coins',
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: intoNext / 1000, minHeight: 8),
                    ),
                  ],
                ),
              ),
            ),
            if (total == 0) ...[
              const SizedBox(height: 24),
              Text(
                'No steps yet. Go to Profile to set up the iPhone Shortcut that syncs your steps.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}
