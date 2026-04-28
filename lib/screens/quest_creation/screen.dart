import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/screens/quest_creation/pages/step_one.dart';
import 'package:techarrow_2026_app/screens/quest_creation/pages/step_three.dart';
import 'package:techarrow_2026_app/screens/quest_creation/pages/step_two.dart';
import 'package:techarrow_2026_app/screens/quest_creation/pages/step_four.dart';
import 'package:techarrow_2026_app/screens/quest_creation/pages/step_five.dart';
import 'package:techarrow_2026_app/services/api.dart';

class QuestCreationScreen extends StatefulWidget {
  const QuestCreationScreen({super.key});

  @override
  State<QuestCreationScreen> createState() => _QuestCreationScreenState();
}

class _QuestCreationScreenState extends State<QuestCreationScreen> {
  QuestCreationPageStatus status = QuestCreationPageStatus.stepOne;
  int checkpointsCount = 0;
  final List<QuestDraftCheckpoint> _checkpoints = [];
  int? _editingCheckpointIndex;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  final TextEditingController _pointTitleController = TextEditingController();
  final TextEditingController _pointTaskController = TextEditingController();
  final TextEditingController _pointCodeWordController =
      TextEditingController();
  final TextEditingController _pointHintController = TextEditingController();
  final TextEditingController _pointRulesController = TextEditingController();
  LatLng? _selectedPoint;
  Uint8List? _coverImageBytes;
  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();

  void changePage(QuestCreationPageStatus newStatus) {
    setState(() {
      status = newStatus;
    });
  }

  void onCheckpointSaved() {
    if (_selectedPoint == null) return;

    final next = QuestDraftCheckpoint(
      title: _pointTitleController.text.trim(),
      task: _pointTaskController.text.trim(),
      correctAnswer: _pointCodeWordController.text.trim(),
      hint: _pointHintController.text.trim(),
      pointRules: _pointRulesController.text.trim(),
      latitude: _selectedPoint!.latitude,
      longitude: _selectedPoint!.longitude,
    );

    if (_editingCheckpointIndex != null) {
      _checkpoints[_editingCheckpointIndex!] = next;
    } else {
      _checkpoints.add(next);
    }

    _pointTitleController.clear();
    _pointTaskController.clear();
    _pointCodeWordController.clear();
    _pointHintController.clear();
    _pointRulesController.clear();
    _selectedPoint = null;
    _editingCheckpointIndex = null;

    setState(() {
      checkpointsCount = _checkpoints.length;
      status = QuestCreationPageStatus.stepFour;
    });
  }

  void _editCheckpoint(int index) {
    final checkpoint = _checkpoints[index];
    _pointTitleController.text = checkpoint.title;
    _pointTaskController.text = checkpoint.task;
    _pointCodeWordController.text = checkpoint.correctAnswer;
    _pointHintController.text = checkpoint.hint;
    _pointRulesController.text = checkpoint.pointRules;
    _selectedPoint = LatLng(checkpoint.latitude, checkpoint.longitude);
    _editingCheckpointIndex = index;
    setState(() {
      status = QuestCreationPageStatus.stepThree;
    });
  }

  void _startCheckpointAt(LatLng point) {
    _pointTitleController.clear();
    _pointTaskController.clear();
    _pointCodeWordController.clear();
    _pointHintController.clear();
    _pointRulesController.clear();
    _selectedPoint = point;
    _editingCheckpointIndex = null;

    setState(() {
      status = QuestCreationPageStatus.stepThree;
    });
  }

  void _dismissCheckpointForm() {
    _pointTitleController.clear();
    _pointTaskController.clear();
    _pointCodeWordController.clear();
    _pointHintController.clear();
    _pointRulesController.clear();
    _selectedPoint = null;
    _editingCheckpointIndex = null;

    setState(() {
      status = QuestCreationPageStatus.stepFour;
    });
  }

  Future<void> _pickCoverImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _coverImageBytes = bytes;
    });
  }

  void _removeCoverImage() {
    setState(() {
      _coverImageBytes = null;
    });
  }

  Future<void> _submitQuest() async {
    if (_isSubmitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: const Text('Вы точно хотите отправить квест на модерацию?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Нет'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Да'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });
    try {
      final points = _checkpoints
          .map(
            (point) => <String, dynamic>{
              'title': point.title,
              'task': point.task,
              'correct_answer': point.correctAnswer,
              'hint': point.hint.isEmpty ? null : point.hint,
              'point_rules': point.pointRules.isEmpty ? null : point.pointRules,
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList();
      final body = BodyCreateQuestApiQuestsPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        difficulty: int.tryParse(_difficultyController.text.trim()) ?? 1,
        durationMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
        rulesAndWarnings: _rulesController.text.trim().isEmpty
            ? null
            : _rulesController.text.trim(),
        points: jsonEncode(points),
      );
      final response = await ApiService.instance.createQuest(
        body: body,
        imageBytes: _coverImageBytes,
      );
      print(response.body);
      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Navigator.of(context).pop();
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось создать квест')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при отправке квеста')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _difficultyController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _pointTitleController.dispose();
    _pointTaskController.dispose();
    _pointCodeWordController.dispose();
    _pointHintController.dispose();
    _pointRulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final Widget currentPage;
    switch (status) {
      case QuestCreationPageStatus.stepOne:
        currentPage = QuestCreationStepOnePage(
          key: ValueKey(status),
          changePage: changePage,
          titleController: _titleController,
          locationController: _locationController,
          difficultyController: _difficultyController,
          durationController: _durationController,
        );
      case QuestCreationPageStatus.stepTwo:
        currentPage = QuestCreationStepTwoPage(
          key: ValueKey(status),
          changePage: changePage,
          descriptionController: _descriptionController,
          rulesController: _rulesController,
          coverImageBytes: _coverImageBytes,
          onPickCoverImage: _pickCoverImage,
          onRemoveCoverImage: _removeCoverImage,
        );
      case QuestCreationPageStatus.stepThree:
        currentPage = QuestCreationStepThreePage(
          key: ValueKey(status),
          changePage: changePage,
          onCheckpointSaved: onCheckpointSaved,
          pointTitleController: _pointTitleController,
          taskController: _pointTaskController,
          codeWordController: _pointCodeWordController,
          hintController: _pointHintController,
          pointRulesController: _pointRulesController,
          selectedPoint: _selectedPoint,
          onPointChanged: (point) {
            setState(() {
              _selectedPoint = point;
            });
          },
          onSheetDismissed: _dismissCheckpointForm,
          isEditing: _editingCheckpointIndex != null,
        );
      case QuestCreationPageStatus.stepFour:
        currentPage = QuestCreationStepFourPage(
          key: ValueKey(status),
          changePage: changePage,
          checkpointsCount: checkpointsCount,
          checkpoints: _checkpoints,
          onCheckpointTap: _editCheckpoint,
          onMapTap: _startCheckpointAt,
        );
      case QuestCreationPageStatus.stepFive:
        currentPage = QuestCreationStepFivePage(
          key: ValueKey(status),
          changePage: changePage,
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          difficulty: _difficultyController.text.trim(),
          durationMinutes: _durationController.text.trim(),
          description: _descriptionController.text.trim(),
          rulesAndWarnings: _rulesController.text.trim(),
          checkpointsCount: checkpointsCount,
          isSubmitting: _isSubmitting,
          onSubmit: _submitQuest,
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: currentPage,
    );
  }
}

enum QuestCreationPageStatus { stepOne, stepTwo, stepThree, stepFour, stepFive }

class QuestDraftCheckpoint {
  const QuestDraftCheckpoint({
    required this.title,
    required this.task,
    required this.correctAnswer,
    required this.hint,
    required this.pointRules,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String task;
  final String correctAnswer;
  final String hint;
  final String pointRules;
  final double latitude;
  final double longitude;
}
