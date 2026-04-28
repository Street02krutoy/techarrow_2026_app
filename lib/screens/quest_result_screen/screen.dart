import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/services/quest.dart';

class QuestResultScreen extends StatelessWidget {
  const QuestResultScreen({super.key, required this.result});

  final QuestRunHistoryItem result;

  String _formatDuration() {
    final d = result.completedAt.difference(result.startedAt).abs();
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h == 0) return '$m:$s';
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Результат квеста',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.questTitle,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Очки: ${result.pointsAwarded}',
                      style: tt.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Длительность: ${_formatDuration()}',
                      style: tt.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('Статус: ${result.status.name}', style: tt.bodyLarge),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  StreamQuestScope.of(context).clearLastRunResult();
                  Navigator.of(context).maybePop();
                },
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
