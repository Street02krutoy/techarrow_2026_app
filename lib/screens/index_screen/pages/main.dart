import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/models/quest.dart';
import 'package:techarrow_2026_app/screens/current_quest_screen/screen.dart';
import 'package:techarrow_2026_app/screens/quest_creation/screen.dart';
import 'package:techarrow_2026_app/services/api.dart';
import 'package:techarrow_2026_app/services/quest.dart';
import 'package:techarrow_2026_app/widgets/event_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isScrolled = false;

  final ScrollController _scrollController = ScrollController();

  static const String _sampleQuestImage =
      'https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcQRZRfRJNfPiR_PG_fa6JHQw3AEYUt0c-oCRwt07bUQRZfdGHhK';

  static const int _pageSize = 20;
  final List<Quest> _quests = <Quest>[];
  _QuestFilters? _activeFilters;
  int _offset = 0;
  int _total = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _refreshQuests();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 0;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
      _maybeLoadMore();
    });
  }

  Quest _mapQuest(QuestResponse item) {
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
  }

  Future<void> _refreshQuests() async {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _loadError = null;
      _offset = 0;
      _total = 0;
      _quests.clear();
    });
    await _loadMore();
  }

  bool get _hasMore => _quests.length < _total;

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore) return;
    if (!_hasMore) return;
    if (_scrollController.position.extentAfter > 800) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _loadError = null;
    });

    try {
      final response = await ApiService.instance.client.apiQuestsGet(
        limit: _pageSize,
        offset: _offset,
        minDurationMinutes: _activeFilters?.minDurationMinutes,
        maxDurationMinutes: _activeFilters?.maxDurationMinutes,
        difficulties: _activeFilters?.difficulties,
        city: _activeFilters?.city,
      );

      final body = response.body;
      if (body == null) {
        throw Exception('Failed to load quests');
      }

      final items = body.items.map(_mapQuest).toList();
      setState(() {
        _total = body.total;
        _offset = body.offset + body.items.length;
        _quests.addAll(items);
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchClose() {
    setState(() {
      _searchController.clear();
    });
  }

  Future<void> _openFiltersSheet() async {
    final filters = await showModalBottomSheet<_QuestFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => const _MainFiltersSheet(),
    );

    if (!mounted || filters == null) return;
    setState(() {
      _activeFilters = filters;
    });
    await _refreshQuests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (_) => const QuestCreationScreen()),
              )
              .then((val) {
                _refreshQuests();
              });
        },
        child: const Icon(Icons.add),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: SafeArea(child: buildSearchBar()),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (StreamQuestScope.of(context).activeSession != null)
            SliverToBoxAdapter(child: buildHeaderCard(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          if (_isInitialLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null && _quests.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Не удалось загрузить квесты'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshQuests,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          else if (_quests.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Квесты не найдены')),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return QuestCard(
                    quest: _quests[index],
                    onFavorite: (val) async {
                      if (val) {
                        await ApiService.instance.client
                            .apiQuestsQuestIdFavoritePost(
                              questId: _quests[index].id,
                            );
                      } else {
                        await ApiService.instance.client
                            .apiQuestsQuestIdFavoriteDelete(
                              questId: _quests[index].id,
                            );
                      }
                      await _refreshQuests();
                    },
                    onReturn: () async {
                      await _refreshQuests();
                    },
                  );
                }, childCount: _quests.length),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: Column(
                  children: [
                    if (_loadError != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Не удалось загрузить ещё'),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _loadMore,
                            child: const Text('Повторить'),
                          ),
                        ],
                      )
                    else if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      )
                    else if (_hasMore)
                      TextButton(
                        onPressed: _loadMore,
                        child: const Text('Загрузить ещё'),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SearchBar(
        controller: _searchController,
        hintText: "Поиск квестов",
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        leading: Icon(Icons.search, color: Colors.grey[700]),
        trailing: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFiltersSheet,
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[700]),
            onPressed: _onSearchClose,
          ),
        ],
      ),
    );
  }

  String formatDurationHms(Duration duration) {
    final d = duration.abs();
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h == 0) {
      return '$mm:$ss';
    }
    final hh = h.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Widget buildHeaderCard(BuildContext context) {
    final quest = StreamQuestScope.of(context).activeSession!;
    final progress = StreamQuestScope.of(context).activeRunProgress;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CurrentQuestScreen()));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(offset: Offset(0, 4), blurRadius: 2, color: Colors.grey),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.only(
                  bottomRight: Radius.circular(16),
                ),
                child: Image.asset("assets/abstract.png"),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.name, style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  _buildSegmentedProgressBar(
                    totalSegments: progress?.totalCheckpoints ?? 4,
                    currentSegment: progress?.currentStepIndex ?? 1,
                  ),
                  SizedBox(height: 8),
                  Text("Количество шагов: ${quest.steps}"),
                  Text("Пройденное время: ${formatDurationHms(quest.elapsed)}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedProgressBar({
    required int totalSegments,
    required int currentSegment,
  }) {
    return Row(
      children: List.generate(totalSegments, (index) {
        final isCompleted = index < currentSegment;
        final isCurrent = index == currentSegment;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.blue
                        : isCurrent
                        ? Colors.blue.withValues(alpha: 0.5)
                        : Colors.grey[400],
                    borderRadius: BorderRadius.horizontal(
                      left: index == 0 ? Radius.circular(2) : Radius.zero,
                      right: index == totalSegments - 1
                          ? Radius.circular(2)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
              if (index < totalSegments - 1) SizedBox(width: 2),
            ],
          ),
        );
      }),
    );
  }
}

class _MainFiltersSheet extends StatelessWidget {
  const _MainFiltersSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    InputDecoration fieldDecoration({bool withArrow = false}) {
      return InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        suffixIcon: withArrow
            ? Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface)
            : null,
      );
    }

    final difficultyController = TextEditingController();
    final cityController = TextEditingController();
    final minDurationController = TextEditingController();
    final maxDurationController = TextEditingController();

    Widget field({
      required String label,
      required TextEditingController controller,
      TextInputType? keyboardType,
      bool withArrow = false,
    }) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: fieldDecoration(withArrow: withArrow).copyWith(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                  ),
                  Expanded(
                    child: Text(
                      'Фильтры',
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Сбросить',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              field(
                label: 'Сложность',
                controller: difficultyController,
                keyboardType: TextInputType.number,
                withArrow: true,
              ),
              const SizedBox(height: 14),
              field(label: 'Город', controller: cityController),
              const SizedBox(height: 14),
              field(
                label: 'Мин. длительность (мин)',
                controller: minDurationController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              field(
                label: 'Макс. длительность (мин)',
                controller: maxDurationController,
                keyboardType: TextInputType.number,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    minimumSize: const Size.fromHeight(64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    final difficulty = int.tryParse(difficultyController.text);
                    final minDuration = int.tryParse(
                      minDurationController.text,
                    );
                    final maxDuration = int.tryParse(
                      maxDurationController.text,
                    );
                    final city = cityController.text.trim();

                    Navigator.of(context).pop(
                      _QuestFilters(
                        difficulties: difficulty != null ? [difficulty] : null,
                        city: city.isEmpty ? null : city,
                        minDurationMinutes: minDuration,
                        maxDurationMinutes: maxDuration,
                      ),
                    );
                  },
                  child: Text(
                    'Применить',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestFilters {
  const _QuestFilters({
    this.minDurationMinutes,
    this.maxDurationMinutes,
    this.difficulties,
    this.city,
  });

  final int? minDurationMinutes;
  final int? maxDurationMinutes;
  final List<dynamic>? difficulties;
  final String? city;
}
