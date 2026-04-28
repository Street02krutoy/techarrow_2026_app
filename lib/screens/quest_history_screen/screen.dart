import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/models/quest.dart';
import 'package:techarrow_2026_app/services/api.dart';
import 'package:techarrow_2026_app/widgets/event_card.dart';

class QuestHistoryScreen extends StatefulWidget {
  const QuestHistoryScreen({super.key});

  @override
  State<QuestHistoryScreen> createState() => _QuestHistoryScreenState();
}

class _QuestHistoryScreenState extends State<QuestHistoryScreen> {
  static const String _sampleQuestImage =
      'https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcQRZRfRJNfPiR_PG_fa6JHQw3AEYUt0c-oCRwt07bUQRZfdGHhK';

  late final Future<List<Quest>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Quest>> _loadHistory() async {
    final res = await ApiService.instance.client.apiQuestRunsHistoryGet();
    final history = res.body ?? <QuestRunHistoryItem>[];

    final futures = history.map((h) async {
      final detailRes = await ApiService.instance.client.apiQuestsQuestIdGet(
        questId: h.questId,
      );
      final item = detailRes.body;

      if (item == null) {
        return Quest(
          id: h.questId,
          isFavorite: false,
          name: h.questTitle,
          duration: '',
          area: '',
          difficulty: '',
          imageSrc: _sampleQuestImage,
        );
      }

      return Quest(
        id: item.id,
        isFavorite: item.isFavourite ?? false,
        name: item.title,
        duration: '${item.durationMinutes} мин',
        area: item.location,
        difficulty: item.difficulty.toString(),
        imageSrc: item.imageFileId != null
            ? "${ApiService.baseUrl.toString()}/api/file/${item.imageFileId}"
            : _sampleQuestImage,
      );
    });

    return Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'История квестов',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Quest>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final quests = snapshot.data ?? <Quest>[];
            if (quests.isEmpty) {
              return const Center(child: Text('История пуста'));
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: quests.length,
              itemBuilder: (context, index) {
                return QuestCard(quest: quests[index], onFavorite: (_) {});
              },
            );
          },
        ),
      ),
    );
  }
}
