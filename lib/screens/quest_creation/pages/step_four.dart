import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:techarrow_2026_app/screens/quest_creation/screen.dart';

class QuestCreationStepFourPage extends StatelessWidget {
  const QuestCreationStepFourPage({
    super.key,
    required this.changePage,
    required this.checkpointsCount,
    required this.checkpoints,
    required this.onCheckpointTap,
  });

  final void Function(QuestCreationPageStatus status) changePage;
  final int checkpointsCount;
  final List<QuestDraftCheckpoint> checkpoints;
  final ValueChanged<int> onCheckpointTap;

  static const LatLng _cityCenter = LatLng(56.3269, 44.0065);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isReady = checkpointsCount >= 3;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _cityCenter,
              initialZoom: 12.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.techarrow_2026_app',
              ),
              MarkerLayer(
                markers: List.generate(checkpoints.length, (index) {
                  final point = checkpoints[index];
                  return Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => onCheckpointTap(index),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: colorScheme.error,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            changePage(QuestCreationPageStatus.stepTwo),
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Создание чекпоинтов',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            changePage(QuestCreationPageStatus.stepThree),
                        icon: Icon(Icons.add, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.17,
            maxChildSize: 0.35,
            builder: (context, scrollController) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Добавлено $checkpointsCount чекпоинта',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'минимум 3 чекпоинта',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isReady
                                ? colorScheme.secondaryContainer
                                : colorScheme.surfaceContainerHighest,
                            foregroundColor: isReady
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: isReady
                              ? () =>
                                    changePage(QuestCreationPageStatus.stepFive)
                              : null,
                          child: Text(
                            'Продолжить',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
