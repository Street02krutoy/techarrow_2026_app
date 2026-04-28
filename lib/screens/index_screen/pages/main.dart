import 'dart:async';

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
  bool _hasSearchText = false;

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
  Timer? _searchDebounce;
  StreamSubscription<TeamQuestRunProgressResponse?>? _teamProgressSub;
  int? _lastNotifiedTeamRunId;
  bool _questScopeSubscribed = false;

  @override
  void initState() {
    super.initState();
    _refreshQuests();
    _searchController.addListener(_onSearchChanged);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questScopeSubscribed) return;
    _questScopeSubscribed = true;
    _teamProgressSub = StreamQuestScope.of(
      context,
    ).onActiveTeamRunProgressChanged.listen((progress) {
      if (!mounted || progress == null) return;
      if (progress.status.value != 'in_progress') return;
      if (_lastNotifiedTeamRunId == progress.runId) return;
      _lastNotifiedTeamRunId = progress.runId;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Командный квест начался')),
      );
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
  bool get _hasActiveFilters => _activeFilters?.hasAny ?? false;

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
      final response = await ApiService.instance.getQuests(
        limit: _pageSize,
        offset: _offset,
        minDurationMinutes: _activeFilters?.minDurationMinutes,
        maxDurationMinutes: _activeFilters?.maxDurationMinutes,
        difficulties: _activeFilters?.difficulties,
        city: _activeFilters?.city,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      final body = response;

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
    _searchDebounce?.cancel();
    _teamProgressSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchClose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);
    setState(() {
      _hasSearchText = false;
    });
    _refreshQuests();
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() {
        _hasSearchText = hasText;
      });
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _refreshQuests);
  }

  Future<void> _openFiltersSheet() async {
    final filters = await showModalBottomSheet<_QuestFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _MainFiltersSheet(initialFilters: _activeFilters),
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
        onSubmitted: (_) {
          _searchDebounce?.cancel();
          _refreshQuests();
        },
        hintText: "Поиск квестов",
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        leading: IconButton(
          icon: const Icon(Icons.tune),
          color: Colors.grey[700],
          onPressed: _openFiltersSheet,
        ),
        trailing: [
          IconButton(
            icon: Icon(
              (_hasSearchText || _hasActiveFilters)
                  ? Icons.close
                  : Icons.search,
              color: Colors.grey[700],
            ),
            onPressed: (_hasSearchText || _hasActiveFilters)
                ? _onSearchClose
                : null,
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

class _MainFiltersSheet extends StatefulWidget {
  const _MainFiltersSheet({this.initialFilters});

  final _QuestFilters? initialFilters;

  @override
  State<_MainFiltersSheet> createState() => _MainFiltersSheetState();
}

class _MainFiltersSheetState extends State<_MainFiltersSheet> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  int? _difficulty;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    if (initial == null) return;
    _cityController.text = initial.city ?? '';
    _minDurationController.text = initial.minDurationMinutes?.toString() ?? '';
    _maxDurationController.text = initial.maxDurationMinutes?.toString() ?? '';
    _difficulty = initial.singleDifficulty;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }

  String _difficultyLabel(int value) {
    return switch (value) {
      1 => 'Очень легко',
      2 => 'Легко',
      3 => 'Средне',
      4 => 'Сложно',
      5 => 'Очень сложно',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    InputDecoration fieldDecoration({String? hint}) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
      );
    }

    Widget field({
      required String label,
      required TextEditingController controller,
      String? hint,
      TextInputType? keyboardType,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: fieldDecoration(hint: hint).copyWith(
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.clear(),
                        ),
                ),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              );
            },
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  'Фильтры',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Сложность',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_difficulty != null)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _difficulty = null),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  key: ValueKey(_difficulty),
                  initialValue: _difficulty,
                  decoration: fieldDecoration(hint: 'Выберите сложность'),
                  dropdownColor: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.primary,
                  ),
                  items: List.generate(5, (index) {
                    final value = index + 1;
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              value.toString(),
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(_difficultyLabel(value)),
                        ],
                      ),
                    );
                  }),
                  onChanged: (value) => setState(() => _difficulty = value),
                ),
                const SizedBox(height: 14),
                field(
                  label: 'Город',
                  controller: _cityController,
                  hint: 'Введите город',
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Длительность, мин',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _minDurationController,
                        builder: (context, value, _) {
                          return TextField(
                            controller: _minDurationController,
                            keyboardType: TextInputType.number,
                            decoration: fieldDecoration(hint: 'От').copyWith(
                              suffixIcon: value.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          _minDurationController.clear(),
                                    ),
                            ),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _maxDurationController,
                        builder: (context, value, _) {
                          return TextField(
                            controller: _maxDurationController,
                            keyboardType: TextInputType.number,
                            decoration: fieldDecoration(hint: 'До').copyWith(
                              suffixIcon: value.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          _maxDurationController.clear(),
                                    ),
                            ),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                      final minDuration = int.tryParse(
                        _minDurationController.text,
                      );
                      final maxDuration = int.tryParse(
                        _maxDurationController.text,
                      );
                      final city = _cityController.text.trim();

                      Navigator.of(context).pop(
                        _QuestFilters(
                          difficulties: _difficulty != null
                              ? [_difficulty]
                              : null,
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

  int? get singleDifficulty =>
      difficulties?.isNotEmpty == true ? difficulties!.first as int? : null;

  bool get hasAny =>
      minDurationMinutes != null ||
      maxDurationMinutes != null ||
      (difficulties?.isNotEmpty ?? false) ||
      (city?.isNotEmpty ?? false);
}
