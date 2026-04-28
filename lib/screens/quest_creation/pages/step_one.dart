import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/screens/quest_creation/screen.dart';

class QuestCreationStepOnePage extends StatelessWidget {
  const QuestCreationStepOnePage({
    super.key,
    required this.changePage,
    required this.titleController,
    required this.locationController,
    required this.difficultyController,
    required this.durationController,
  });

  final void Function(QuestCreationPageStatus status) changePage;
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController difficultyController;
  final TextEditingController durationController;

  InputDecoration _fieldDecoration(
    BuildContext context, {
    bool hasDropdown = false,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      suffixIcon: hasDropdown
          ? Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface)
          : null,
    );
  }

  Widget _label(BuildContext context, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Создание квеста',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              _label(context, 'Название'),
              TextField(
                controller: titleController,
                decoration: _fieldDecoration(context, hint: 'Крутой квест'),
              ),
              const SizedBox(height: 14),
              _label(context, 'Район/город'),
              TextField(
                controller: locationController,
                decoration: _fieldDecoration(context, hint: 'Москва'),
              ),
              const SizedBox(height: 14),
              _label(context, 'Сложность'),
              TextField(
                controller: difficultyController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(
                  context,
                  hasDropdown: true,
                  hint: '1-5',
                ),
              ),
              const SizedBox(height: 14),
              _label(context, 'Длительность'),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(context, hint: '40'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () => changePage(QuestCreationPageStatus.stepTwo),
                  child: Text(
                    'Далее',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
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
