import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/screens/quest_creation/screen.dart';

class QuestCreationStepOnePage extends StatefulWidget {
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

  @override
  State<QuestCreationStepOnePage> createState() =>
      _QuestCreationStepOnePageState();
}

class _QuestCreationStepOnePageState extends State<QuestCreationStepOnePage> {
  bool get _canProceed =>
      widget.titleController.text.trim().isNotEmpty &&
      widget.locationController.text.trim().isNotEmpty &&
      widget.difficultyController.text.trim().isNotEmpty &&
      widget.durationController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.titleController.addListener(_refresh);
    widget.locationController.addListener(_refresh);
    widget.durationController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.titleController.removeListener(_refresh);
    widget.locationController.removeListener(_refresh);
    widget.durationController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
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

  Widget _difficultyDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentValue = int.tryParse(widget.difficultyController.text.trim());

    return DropdownButtonFormField<int>(
      initialValue:
          currentValue != null && currentValue >= 1 && currentValue <= 5
          ? currentValue
          : null,
      decoration: _fieldDecoration(context, hint: 'Выберите сложность'),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      items: List.generate(5, (index) {
        final value = index + 1;
        return DropdownMenuItem<int>(
          value: value,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value.toString(),
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _difficultyLabel(value),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            widget.difficultyController.text = value.toString();
          });
        }
      },
    );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Создание квеста',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _label(context, 'Название'),
                      TextField(
                        controller: widget.titleController,
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Введите название',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label(context, 'Район/город'),
                      TextField(
                        controller: widget.locationController,
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Введите район или город',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label(context, 'Сложность'),
                      _difficultyDropdown(context),
                      const SizedBox(height: 14),
                      _label(context, 'Длительность, мин'),
                      TextField(
                        controller: widget.durationController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Введите длительность в минутах',
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
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
                          onPressed: _canProceed
                              ? () => widget.changePage(
                                  QuestCreationPageStatus.stepTwo,
                                )
                              : null,
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
          },
        ),
      ),
    );
  }
}
