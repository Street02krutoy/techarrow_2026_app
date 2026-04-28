import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/models/quest.dart';
import 'package:techarrow_2026_app/models/streaming_quest_session.dart';
import 'package:techarrow_2026_app/services/api.dart';

/// Provides [StreamQuest] to the widget tree (same pattern as [StreamAuthScope]).
class StreamQuestScope extends InheritedNotifier<StreamQuestNotifier> {
  StreamQuestScope({super.key, required super.child})
    : super(notifier: StreamQuestNotifier());

  static StreamQuest of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StreamQuestScope>()!
        .notifier!
        .streamQuest;
  }
}

class StreamQuestNotifier extends ChangeNotifier {
  StreamQuestNotifier() : streamQuest = StreamQuest() {
    streamQuest.onActiveSessionChanged.listen((_) => notifyListeners());
    streamQuest.onActiveRunProgressChanged.listen((_) => notifyListeners());
    streamQuest.onLastRunResultChanged.listen((_) => notifyListeners());
  }

  final StreamQuest streamQuest;

  @override
  void dispose() {
    streamQuest.dispose();
    super.dispose();
  }
}

/// Tracks the active quest run: physical steps + elapsed time from session start.
class StreamQuest with WidgetsBindingObserver {
  StreamQuest()
    : _controller = StreamController<StreamingQuestSession?>.broadcast() {
    _controller.stream.listen((StreamingQuestSession? next) {
      _session = next;
    });
    // Note: this controller was added later; keep it nullable so hot-reload
    // doesn't crash on older in-memory instances.
    _progressController =
        StreamController<QuestRunProgressResponse?>.broadcast();
    _progressController?.stream.listen((QuestRunProgressResponse? next) {
      _activeRunProgress = next;
    });
    _lastRunResultController =
        StreamController<QuestRunHistoryItem?>.broadcast();
    _lastRunResultController?.stream.listen((QuestRunHistoryItem? next) {
      _lastRunResult = next;
    });
    WidgetsBinding.instance.addObserver(this);
  }

  StreamingQuestSession? _session;
  StreamingQuestSession? get activeSession => _session;

  Stream<StreamingQuestSession?> get onActiveSessionChanged =>
      _controller.stream;

  final StreamController<StreamingQuestSession?> _controller;

  QuestRunProgressResponse? _activeRunProgress;
  QuestRunProgressResponse? get activeRunProgress => _activeRunProgress;

  Stream<QuestRunProgressResponse?> get onActiveRunProgressChanged =>
      _progressController?.stream ?? const Stream.empty();

  StreamController<QuestRunProgressResponse?>? _progressController;

  QuestRunHistoryItem? _lastRunResult;
  QuestRunHistoryItem? get lastRunResult => _lastRunResult;

  Stream<QuestRunHistoryItem?> get onLastRunResultChanged =>
      _lastRunResultController?.stream ?? const Stream.empty();

  StreamController<QuestRunHistoryItem?>? _lastRunResultController;

  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _elapsedTicker;
  int? _baselineTotalSteps;
  DateTime? _startedAt;
  int? _activeQuestId;
  String? _activeQuestName;

  /// Starts tracking [catalogQuest]: pedometer steps since now and wall time from [startedAt].
  ///
  /// Returns `false` if activity recognition permission was denied (Android) or tracking failed.
  Future<bool> startSession(Quest catalogQuest) async {
    stopSession();
    clearLastRunResult();

    if (kIsWeb) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        return false;
      }
    }

    _startedAt = DateTime.now();
    _activeQuestId = catalogQuest.id;
    _activeQuestName = catalogQuest.name;
    _baselineTotalSteps = null;

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount stepCount) {
          final totalSteps = stepCount.steps;
          _baselineTotalSteps ??= totalSteps;
          final delta = (totalSteps - _baselineTotalSteps!)
              .clamp(0, 1 << 30)
              .toInt();
          if (_startedAt == null ||
              _activeQuestId == null ||
              _activeQuestName == null) {
            return;
          }
          _emit(
            StreamingQuestSession(
              questId: _activeQuestId!,
              name: _activeQuestName!,
              startedAt: _startedAt!,
              steps: delta,
            ),
          );
        },
        onError: _onStepStreamError,
        cancelOnError: false,
      );
    } catch (_) {
      stopSession();
      return false;
    }

    _emit(
      StreamingQuestSession(
        questId: catalogQuest.id,
        name: catalogQuest.name,
        startedAt: _startedAt!,
        steps: 0,
      ),
    );

    _startElapsedTicker();
    await refreshActiveRunProgress();

    return true;
  }

  void _startElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = _session;
      if (s == null) return;
      _emit(s.copyWith());
    });
  }

  Future<void> refreshActiveRunProgress() async {
    if (_session == null) return;
    try {
      final res = await ApiService.instance.client.apiQuestRunsActiveGet();
      final body = res.body;
      if (res.isSuccessful && body != null) {
        _progressController?.add(body);
      }
    } catch (_) {
      // ignore: UI can continue with existing state
    }
  }

  void setActiveRunProgress(QuestRunProgressResponse progress) {
    _progressController?.add(progress);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final s = _session;
    if (s == null) return;

    if (state == AppLifecycleState.resumed) {
      // Trigger an immediate refresh so elapsed time/steps update right away.
      _emit(s.copyWith());
      _startElapsedTicker();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Keep the latest snapshot for listeners before app loses focus.
      _emit(s.copyWith());
    }
  }

  /// Step count unavailable (e.g. simulator, unsupported device): stop counting, keep session at 0 steps.
  void _onStepStreamError(Object error, StackTrace _) {
    if (!_isStepCountUnavailableError(error)) {
      return;
    }
    _cancelStepSubscriptionSilently();
    if (_startedAt != null &&
        _activeQuestId != null &&
        _activeQuestName != null) {
      _emit(
        StreamingQuestSession(
          questId: _activeQuestId!,
          name: _activeQuestName!,
          startedAt: _startedAt!,
          steps: 0,
        ),
      );
    }
  }

  bool _isStepCountUnavailableError(Object error) {
    if (error is PlatformException) {
      if (error.code == '3') return true;
      final msg = error.message ?? '';
      if (msg.contains('not available') ||
          msg.contains('Step Count is not available')) {
        return true;
      }
    }
    return false;
  }

  void _cancelStepSubscriptionSilently() {
    try {
      _stepSubscription?.cancel();
    } catch (_) {}
    _stepSubscription = null;
  }

  void _emit(StreamingQuestSession next) {
    _controller.add(next);
  }

  /// Stops step tracking and clears the active session.
  void stopSession() {
    _cancelStepSubscriptionSilently();
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
    _activeRunProgress = null;
    _progressController?.add(null);
    _baselineTotalSteps = null;
    _startedAt = null;
    _activeQuestId = null;
    _activeQuestName = null;
    _controller.add(null);
  }

  void clearLastRunResult() {
    _lastRunResult = null;
    _lastRunResultController?.add(null);
  }

  void dispose() {
    stopSession();
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
    _progressController?.close();
    _lastRunResultController?.close();
  }
}
