import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/services/api.dart';
import 'package:techarrow_2026_app/services/auth.dart';
import 'package:techarrow_2026_app/services/team.dart';

class TeamWaitingRoomSheet extends StatefulWidget {
  const TeamWaitingRoomSheet({
    super.key,
    required this.questId,
    this.questTitle,
  });

  final int questId;
  final String? questTitle;

  @override
  State<TeamWaitingRoomSheet> createState() => _TeamWaitingRoomSheetState();
}

class _TeamWaitingRoomSheetState extends State<TeamWaitingRoomSheet> {
  bool _isReady = false;
  bool _isUpdating = false;
  TeamQuestRunProgressResponse? _progress;

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  Future<void> _refreshProgress() async {
    try {
      final res = await ApiService.instance.client.apiTeamQuestRunsActiveGet();
      if (!mounted) return;
      if (res.isSuccessful && res.body != null) {
        setState(() {
          _progress = res.body;
        });
      }
    } catch (_) {}
  }

  Future<void> _setReady(bool value) async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
    });
    try {
      final res = await ApiService.instance.client.apiTeamQuestRunsPatch(
        body: TeamQuestRunReadinessRequest(
          questId: widget.questId,
          isReady: value,
        ),
      );
      if (!mounted) return;
      if (res.isSuccessful && res.body != null) {
        setState(() {
          _isReady = value;
          _progress = res.body;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось обновить статус')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось обновить статус')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final team = StreamTeamScope.of(context).team;
    final me = StreamAuthScope.of(context).currentUser;
    final members = team?.members ?? const <TeamMemberResponse>[];
    final readyIds = _progress?.readyMemberIds ?? const <int>[];
    const desiredTeamSize = 6;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
              ],
            ),
            Text(
              team?.name ?? 'Команда',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${team?.code ?? '—'}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: members.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = members[index];
                  final isReadyMember =
                      readyIds.contains(m.id) || (me?.id == m.id && _isReady);
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.username,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              me != null && me.id == m.id ? me.email : '',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isReadyMember)
                        Icon(Icons.check_circle, color: cs.primary)
                      else
                        Icon(Icons.radio_button_unchecked, color: cs.outline),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'В команде должно быть ровно $desiredTeamSize человек',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _isUpdating ? null : () => _setReady(!_isReady),
                child: Text(
                  _isReady ? 'Не готов' : 'Готов',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
