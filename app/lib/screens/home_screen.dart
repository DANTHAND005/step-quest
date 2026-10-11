import 'package:flutter/material.dart';

import '../api.dart';
import 'friends_tab.dart';
import 'leaderboard_tab.dart';
import 'profile_tab.dart';
import 'today_tab.dart';

/// The bottom navigation bar and whichever tab is open.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});

  final Api api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _refreshes = 0;

  @override
  Widget build(BuildContext context) {
    final api = widget.api;

    // New tab? Add one line here.
    final tabs = [
      (title: 'Today', icon: Icons.directions_walk, page: TodayTab(api: api)),
      (title: 'Leaderboard', icon: Icons.leaderboard, page: LeaderboardTab(api: api)),
      (title: 'Friends', icon: Icons.people, page: FriendsTab(api: api)),
      (title: 'Profile', icon: Icons.person, page: ProfileTab(api: api)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_tab].title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _refreshes++),
          ),
        ],
      ),
      // A new key rebuilds the tab, which reloads its data.
      // That happens when you switch tabs or press Refresh.
      body: KeyedSubtree(
        key: ValueKey('$_tab-$_refreshes'),
        child: tabs[_tab].page,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final tab in tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.title),
        ],
      ),
    );
  }
}
