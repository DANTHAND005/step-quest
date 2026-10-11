import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

/// You and your friends ranked by steps, for today or the last 7 days.
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key, required this.api});

  final Api api;

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  String _range = 'week';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Today')),
                ButtonSegment(value: 'week', label: Text('Last 7 days')),
              ],
              selected: {_range},
              onSelectionChanged: (picked) => setState(() => _range = picked.first),
            ),
          ),
        ),
        Expanded(
          child: LoadView<List<dynamic>>(
            key: ValueKey(_range), // switching range reloads
            load: () => widget.api.leaderboard(_range),
            builder: (context, rows, reload) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final (i, row) in rows.indexed)
                  _RankRow(
                    rank: i + 1,
                    name: row['username'] as String,
                    steps: row['steps'] as int,
                    isMe: row['username'] == widget.api.username,
                  ),
                if (rows.length <= 1)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Add friends in the Friends tab to see how you stack up.',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.name, required this.steps, required this.isMe});

  final int rank;
  final String name;
  final int steps;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: isMe ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              child: Text('$rank', style: text.titleLarge, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 12),
            Avatar(name),
          ],
        ),
        title: Text(isMe ? '$name · you' : name),
        trailing: Text('${formatNumber(steps)} steps', style: text.titleMedium),
      ),
    );
  }
}
