import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/models/quest.dart';
import 'package:techarrow_2026_app/screens/current_quest_screen/screen.dart';
import 'package:techarrow_2026_app/screens/quest_data/team_waiting_room_sheet.dart';
import 'package:techarrow_2026_app/services/api.dart';
import 'package:techarrow_2026_app/services/auth.dart';
import 'package:techarrow_2026_app/services/quest.dart';

class QuestDataScreen extends StatefulWidget {
  const QuestDataScreen({super.key, required this.quest});

  final Quest quest;

  @override
  State<QuestDataScreen> createState() => _QuestDataScreenState();
}

class _QuestDataScreenState extends State<QuestDataScreen> {
  late Quest _quest;
  bool _isTogglingFavorite = false;
  String? _description;
  String? _rulesAndWarnings;
  bool _isLoadingDetail = false;
  int? _creatorId;
  bool _isSendingComplaint = false;
  bool _isExportingPdf = false;

  bool get _canStartQuest {
    final status = _quest.status?.toLowerCase();
    final questState = StreamQuestScope.of(context);
    final hasActiveRun =
        questState.activeSession != null ||
        questState.activeTeamRunProgress != null;
    return (status == null || status == 'approved') && !hasActiveRun;
  }

  bool get _canReport {
    final me = StreamAuthScope.of(context).currentUser;
    if (me == null || _creatorId == null) return false;
    return _creatorId != me.id;
  }

  @override
  void initState() {
    super.initState();
    _quest = widget.quest;
    _loadQuestDetail();
  }

  Future<void> _loadQuestDetail() async {
    setState(() {
      _isLoadingDetail = true;
    });
    try {
      final res = await ApiService.instance.client.apiQuestsQuestIdGet(
        questId: _quest.id,
      );
      final detail = res.body;
      if (!mounted || detail == null) return;
      setState(() {
        _description = detail.description;
        _rulesAndWarnings = detail.rulesAndWarnings;
        _creatorId = detail.creator.id;
        _quest = _quest.copyWith(
          checkpointsCount: detail.points.length,
          imageSrc: detail.imageFileId != null
              ? "${ApiService.baseUrl.toString()}/api/file/${detail.imageFileId}"
              : _quest.imageSrc,
        );
      });
    } catch (_) {
      // keep fallback placeholders when detail loading fails
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    final prev = _quest.isFavorite;

    setState(() {
      _isTogglingFavorite = true;
      _quest = _quest.copyWith(isFavorite: !prev);
    });

    try {
      if (!prev) {
        await ApiService.instance.client.apiQuestsQuestIdFavoritePost(
          questId: _quest.id,
        );
      } else {
        await ApiService.instance.client.apiQuestsQuestIdFavoriteDelete(
          questId: _quest.id,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quest = _quest.copyWith(isFavorite: prev);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось обновить избранное')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  void _showStartQuestSheet(BuildContext context) {
    var soloMode = true;
    var isStartingRun = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        final tt = Theme.of(sheetContext).textTheme;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 16,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
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
                  const SizedBox(height: 16),
                  Text(
                    'Начни квест в одиночку или с командой',
                    textAlign: TextAlign.center,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outline),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: soloMode
                                ? cs.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => setModalState(() => soloMode = true),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Один',
                                  textAlign: TextAlign.center,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: soloMode
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Material(
                            color: !soloMode
                                ? cs.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  setModalState(() => soloMode = false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'С командой',
                                  textAlign: TextAlign.center,
                                  style: tt.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: soloMode
                                        ? cs.onSurface
                                        : cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (isStartingRun) return;
                      setModalState(() {
                        isStartingRun = true;
                      });

                      final navigator = Navigator.of(context);
                      final surface = Theme.of(context).colorScheme.surface;
                      if (soloMode) {
                        final startRes = await ApiService.instance.client
                            .apiQuestRunsPost(
                              body: QuestRunStartRequest(
                                questId: widget.quest.id,
                              ),
                            );

                        if (!context.mounted) return;
                        if (!startRes.isSuccessful || startRes.body == null) {
                          setModalState(() {
                            isStartingRun = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось запустить квест'),
                            ),
                          );
                          return;
                        }
                        final initialProgress = startRes.body!;
                        final started = await StreamQuestScope.of(
                          context,
                        ).startSession(_quest);
                        if (!context.mounted) return;
                        if (!started) {
                          setModalState(() {
                            isStartingRun = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Не удалось включить локальный трекинг',
                              ),
                            ),
                          );
                          return;
                        }
                        StreamQuestScope.of(
                          context,
                        ).setActiveRunProgress(initialProgress);
                        navigator.pop(); // close bottom sheet
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const CurrentQuestScreen(),
                          ),
                        );
                        return;
                      } else {
                        navigator.pop(); // close bottom sheet
                        if (!context.mounted) return;
                        setModalState(() {
                          isStartingRun = false;
                        });
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (_) => TeamWaitingRoomSheet(
                            questId: _quest.id,
                            questTitle: _quest.name,
                            quest: _quest,
                          ),
                        );
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(sheetContext).primaryColorLight,
                      ),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        isStartingRun ? 'Запуск...' : 'Начать',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _reportQuest() async {
    if (_isSendingComplaint) return;
    final reasonCtrl = TextEditingController();
    try {
      final reason = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          final cs = Theme.of(sheetContext).colorScheme;
          final tt = Theme.of(sheetContext).textTheme;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
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
                const SizedBox(height: 14),
                Text(
                  'Пожаловаться на квест',
                  textAlign: TextAlign.center,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 4,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Опишите причину жалобы',
                    hintStyle: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.all(14),
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
                      borderSide: BorderSide(color: cs.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.secondaryContainer,
                      foregroundColor: cs.onSecondaryContainer,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(reasonCtrl.text.trim()),
                    child: Text(
                      'Отправить',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted || reason == null) return;
      if (reason.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Укажите причину жалобы')));
        return;
      }
      setState(() {
        _isSendingComplaint = true;
      });
      final res = await ApiService.instance.client
          .apiQuestsQuestIdComplaintsPost(
            questId: _quest.id,
            body: QuestComplaintCreateRequest(reason: reason),
          );
      if (!mounted) return;
      if (res.isSuccessful) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Жалоба отправлена')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить жалобу')),
        );
      }
    } finally {
      reasonCtrl.dispose();
      if (mounted) {
        setState(() {
          _isSendingComplaint = false;
        });
      }
    }
  }

  Future<void> _downloadQuestPdf() async {
    if (_isExportingPdf) return;
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Скачивание PDF на web не поддерживается'),
        ),
      );
      return;
    }
    setState(() {
      _isExportingPdf = true;
    });
    try {
      final res = await ApiService.instance.client.apiQuestsQuestIdExportGet(
        questId: _quest.id,
      );
      final bytes = res.bodyBytes;
      if (!mounted) return;
      if (!res.isSuccessful || bytes.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Не удалось скачать PDF')));
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = _quest.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(' ', '_');
      final file = File('${dir.path}/quest_${_quest.id}_$safeName.pdf');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Экспорт квеста',
          text: 'Экспорт квеста "${_quest.name}"',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось скачать PDF')));
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _quest.name,
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Скачать PDF',
            onPressed: _isExportingPdf ? null : _downloadQuestPdf,
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
          if (_canReport)
            IconButton(
              tooltip: 'Пожаловаться',
              onPressed: _isSendingComplaint ? null : _reportQuest,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 48.0),
            child: Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(
                      colorScheme: cs,
                      textTheme: tt,
                      quest: _quest,
                      isTogglingFavorite: _isTogglingFavorite,
                      onToggleFavorite: _toggleFavorite,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Описание',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 150),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isLoadingDetail
                          ? const Center(child: CircularProgressIndicator())
                          : Text(
                              (_description != null && _description!.isNotEmpty)
                                  ? _description!
                                  : 'Описание отсутствует',
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Правила и предупреждения',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 150),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isLoadingDetail
                          ? const Center(child: CircularProgressIndicator())
                          : Text(
                              (_rulesAndWarnings != null &&
                                      _rulesAndWarnings!.isNotEmpty)
                                  ? _rulesAndWarnings!
                                  : 'Правила и предупреждения отсутствуют',
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Spacer(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canStartQuest
                              ? () => _showStartQuestSheet(context)
                              : null,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.disabled)) {
                                return Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest;
                              }
                              return Theme.of(context).primaryColorLight;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.disabled)) {
                                return Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant;
                              }
                              return Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer;
                            }),
                            shadowColor: WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _canStartQuest ? 'Начать' : 'Идет другой квест',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.colorScheme,
    required this.textTheme,
    required this.quest,
    required this.isTogglingFavorite,
    required this.onToggleFavorite,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Quest quest;
  final bool isTogglingFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final district = quest.district ?? '—';
    final checkpoints = quest.checkpointsCount != null
        ? '${quest.checkpointsCount}'
        : '—';
    final status = quest.status ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              quest.imageSrc,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: colorScheme.surfaceContainerHigh,
                alignment: Alignment.center,
                child: Icon(Icons.broken_image, color: colorScheme.outline),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Характеристики',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                quest.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: quest.isFavorite
                    ? colorScheme.error
                    : colorScheme.outline,
              ),
              onPressed: isTogglingFavorite ? null : onToggleFavorite,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _detailLine(textTheme, colorScheme, 'Сложность:', quest.difficulty),
        _detailLine(textTheme, colorScheme, 'Длительность:', quest.duration),
        _detailLine(textTheme, colorScheme, 'Город:', quest.area),
        _detailLine(textTheme, colorScheme, 'Район:', district),
        _detailLine(textTheme, colorScheme, 'Кол-во чекпоинтов:', checkpoints),
        _detailLine(textTheme, colorScheme, 'Статус:', status),
      ],
    );
  }

  Widget _detailLine(TextTheme tt, ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label $value',
        style: tt.bodyLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
