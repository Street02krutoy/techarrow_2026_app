import 'dart:async';

import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/models/quest.dart';
import 'package:techarrow_2026_app/screens/quest_data/screen.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onFavorite,
    this.onReturn,
    this.showFavourite = true,
  });

  final Quest quest;
  final bool showFavourite;
  final void Function(bool value) onFavorite;
  final FutureOr<dynamic> Function()? onReturn;

  void _openPreview(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => QuestDataScreen(quest: quest),
          ),
        )
        .then((_) {
          if (onReturn != null) {
            onReturn!();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPreview(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                quest.imageSrc,
                height: 120,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text('Сложность: ${quest.difficulty}'),
                      Text('Длительность: ${quest.duration}'),
                      Text('Город: ${quest.area}'),
                      if (quest.status != null)
                        Text(
                          '${quest.status}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                if (showFavourite)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => onFavorite(!quest.isFavorite),
                      icon: Icon(
                        quest.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: quest.isFavorite ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
