import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/screens/index_screen/pages/leaderboard.dart';

class LeaderboardEntry {
  const LeaderboardEntry({required this.place, required this.title});

  final int place;
  final String title;
}

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    super.key,
    required this.entries,
    required this.activeTab,
    required this.changePage,
    required this.withAvatar,
    required this.currentUserPlace,
    this.body,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardPageStatus activeTab;
  final void Function(LeaderboardPageStatus status) changePage;
  final bool withAvatar;
  final int currentUserPlace;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            children: [
              const Text(
                'Рейтинг',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              _LeaderboardTabs(activeTab: activeTab, changePage: changePage),
              const SizedBox(height: 26),
              Expanded(
                child: body ??
                    ListView.separated(
                      padding: const EdgeInsets.only(right: 2),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _LeaderboardRow(
                          place: entry.place,
                          title: entry.title,
                          withAvatar: withAvatar,
                          isCurrentUser: entry.place == currentUserPlace,
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardTabs extends StatelessWidget {
  const _LeaderboardTabs({required this.activeTab, required this.changePage});

  final LeaderboardPageStatus activeTab;
  final void Function(LeaderboardPageStatus status) changePage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: 'Личный',
              isActive: activeTab == LeaderboardPageStatus.personal,
              onTap: () => changePage(LeaderboardPageStatus.personal),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Командный',
              isActive: activeTab == LeaderboardPageStatus.command,
              onTap: () => changePage(LeaderboardPageStatus.command),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD6E4F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.place,
    required this.title,
    required this.withAvatar,
    required this.isCurrentUser,
  });

  final int place;
  final String title;
  final bool withAvatar;
  final bool isCurrentUser;

  Color? _placeColor(int value) {
    if (value == 1) return const Color(0xFFEAF25B);
    if (value == 2) return const Color(0xFFE9E9E9);
    if (value == 3) return const Color(0xFFF0D5BB);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _placeColor(place),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4F5C73),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (withAvatar) ...[
          const CircleAvatar(
            radius: 11,
            backgroundColor: Color(0xFFE2E7FB),
            child: Icon(
              Icons.person_outline_rounded,
              size: 14,
              color: Color(0xFF6478A9),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF63769D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (isCurrentUser)
          const CircleAvatar(radius: 6, backgroundColor: Color(0xFFD0E1F6)),
      ],
    );
  }
}
