import 'package:flutter/material.dart';

/// Profile edit: nickname, date of birth, email, password — layout per design mock.
class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  static const Color _fieldFill = Color(0xFFEBF0F5);
  static const Color _saveButtonFill = Color(0xFFD9E6F2);

  final _nicknameCtrl = TextEditingController(text: 'patisson');
  final _dobCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _fieldFill,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Редактирование',
          style: textTheme.titleLarge?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _labeledBlock(
                label: 'Никнейм',
                child: TextField(
                  controller: _nicknameCtrl,
                  style: textTheme.bodyLarge?.copyWith(color: onSurface),
                  decoration: _fieldDecoration(context),
                ),
                textTheme: textTheme,
                onSurface: onSurface,
              ),
              const SizedBox(height: 20),
              _labeledBlock(
                label: 'Дата рождения',
                child: TextField(
                  controller: _dobCtrl,
                  keyboardType: TextInputType.datetime,
                  style: textTheme.bodyLarge?.copyWith(color: onSurface),
                  decoration: _fieldDecoration(context, hintText: 'ДД.ММ.ГГГГ'),
                ),
                textTheme: textTheme,
                onSurface: onSurface,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _saveButtonFill,
                    foregroundColor: onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    'Сохранить',
                    style: textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w500,
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

  Widget _labeledBlock({
    required String label,
    required Widget child,
    required TextTheme textTheme,
    required Color onSurface,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
