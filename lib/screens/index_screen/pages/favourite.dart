import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/models/quest.dart';
import 'package:techarrow_2026_app/services/api.dart';
import 'package:techarrow_2026_app/widgets/event_card.dart';

enum _MyQuestsTab { favourites, created }

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  static const String _sampleQuestImage =
      'https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcQRZRfRJNfPiR_PG_fa6JHQw3AEYUt0c-oCRwt07bUQRZfdGHhK';

  late Future<List<Quest>> _favoritesFuture;
  late Future<List<Quest>> _createdFuture;
  _MyQuestsTab _tab = _MyQuestsTab.favourites;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
    _createdFuture = _loadCreated();
  }

  Future<List<Quest>> _loadFavorites() async {
    final res = await ApiService.instance.client.apiQuestsFavoritesGet();
    final items = res.body?.items ?? <QuestResponse>[];

    return items
        .map(
          (item) => Quest(
            id: item.id,
            isFavorite: item.isFavourite ?? true,
            name: item.title,
            duration: '${item.durationMinutes} мин',
            area: item.location,
            difficulty: item.difficulty.toString(),
            imageSrc: item.imageFileId != null
                ? "${ApiService.baseUrl.toString()}/api/file/${item.imageFileId}"
                : _sampleQuestImage,
          ),
        )
        .toList();
  }

  Future<List<Quest>> _loadCreated() async {
    final res = await ApiService.instance.client.apiQuestsMyGet();
    final items = res.body?.items ?? <QuestResponse>[];

    return items
        .map(
          (item) => Quest(
            id: item.id,
            isFavorite: item.isFavourite ?? false,
            name: item.title,
            duration: '${item.durationMinutes} мин',
            area: item.location,
            difficulty: item.difficulty.toString(),
            imageSrc: item.imageFileId != null
                ? "${ApiService.baseUrl.toString()}/api/file/${item.imageFileId}"
                : _sampleQuestImage,
          ),
        )
        .toList();
  }

  void _setTab(_MyQuestsTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
    });
  }

  Future<void> _toggleFavorite(Quest quest, bool value) async {
    if (value) {
      await ApiService.instance.client.apiQuestsQuestIdFavoritePost(
        questId: quest.id,
      );
    } else {
      await ApiService.instance.client.apiQuestsQuestIdFavoriteDelete(
        questId: quest.id,
      );
    }

    setState(() {
      _favoritesFuture = _loadFavorites();
      _createdFuture = _loadCreated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Мои квесты',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _TabSlider(active: _tab, onChanged: _setTab),
            ),
            Expanded(
              child: FutureBuilder<List<Quest>>(
                future: _tab == _MyQuestsTab.favourites
                    ? _favoritesFuture
                    : _createdFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final quests = snapshot.data ?? <Quest>[];
                  if (quests.isEmpty) {
                    return Center(
                      child: Text(
                        _tab == _MyQuestsTab.favourites
                            ? 'Нет избранных квестов'
                            : 'Нет созданных квестов',
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      final quest = quests[index];
                      return QuestCard(
                        quest: quest,
                        onFavorite: (value) async {
                          await _toggleFavorite(quest, value);
                        },
                        onReturn: () async {
                          setState(() {
                            _favoritesFuture = _loadFavorites();
                            _createdFuture = _loadCreated();
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSlider extends StatelessWidget {
  const _TabSlider({required this.active, required this.onChanged});

  final _MyQuestsTab active;
  final void Function(_MyQuestsTab tab) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.outlineVariant;
    final activeColor = const Color(0xFFD6E4F2);

    Widget tabButton({
      required String title,
      required bool isActive,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: isActive ? activeColor : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(28),
          color: cs.surface,
        ),
        child: Row(
          children: [
            tabButton(
              title: 'Избранное',
              isActive: active == _MyQuestsTab.favourites,
              onTap: () => onChanged(_MyQuestsTab.favourites),
            ),
            Container(width: 1, color: borderColor),
            tabButton(
              title: 'Созданное',
              isActive: active == _MyQuestsTab.created,
              onTap: () => onChanged(_MyQuestsTab.created),
            ),
          ],
        ),
      ),
    );
  }
}
