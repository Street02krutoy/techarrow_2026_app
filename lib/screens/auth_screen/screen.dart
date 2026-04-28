import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/services/auth.dart';
import 'package:techarrow_2026_app/services/team.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

enum _ScreenStates { regFirst, regLast, login }

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? birthdate;
  final _nicknameController = TextEditingController();
  bool _hidePassword = true;
  _ScreenStates _state = _ScreenStates.login;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {});

    final success = await StreamAuthScope.of(
      context,
    ).signIn(_emailController.text, _passwordController.text);

    if (!mounted) return;

    if (success) {
      await StreamTeamScope.of(context).refresh();
    }

    setState(() {});
  }

  Future<void> _signOn() async {
    setState(() {});

    final success = await StreamAuthScope.of(context).signOn(
      _emailController.text,
      _passwordController.text,
      _nicknameController.text,
      birthdate!,
    );

    if (!mounted) return;

    if (success) {
      await StreamTeamScope.of(context).refresh();
    }

    setState(() {});
  }

  setScreenState(_ScreenStates newState) {
    setState(() {
      _state = newState;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _state == _ScreenStates.regLast
                ? _buildRegistrationSecond(context)
                : _state == _ScreenStates.regFirst
                ? _buildRegistrationFirst(context)
                : _buildLogin(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationFirst(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 70),
      Text(
        'Регистрация',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: MediaQuery.of(context).size.width / 1.2,
        child: Text(
          'Заполните свои данные для регистрации',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
      _buildField(
        context,
        label: "Никнейм",
        controller: _nicknameController,
        hint: "Алексей Базин",
      ),
      const SizedBox(height: 24),
      _buildDateField(
        context,
        label: "Дата рождения",
        hint: "ДД/ММ/ГГГГ",
        selectedDate: birthdate,
        onDateSelected: (date) {
          setState(() {
            birthdate = date;
          });
        },
      ),

      const SizedBox(height: 48),
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).primaryColorLight,
                ),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
              ),
              onPressed: () => setScreenState(_ScreenStates.regLast),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Далее"),
              ),
            ),
          ),
        ],
      ),
      Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          Text("Есть аккаунт?"),
          InkWell(
            onTap: () {
              setScreenState(_ScreenStates.login);
            },
            child: Text(
              "Войти",
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildRegistrationSecond(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => setScreenState(_ScreenStates.regFirst),
            iconSize: 24,
            icon: Icon(Icons.arrow_back),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Text(
        'Регистрация',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: MediaQuery.of(context).size.width / 1.2,
        child: Text(
          'Заполните свои данные для регистрации',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
      _buildField(
        context,
        label: "Логин",
        controller: _emailController,
        hint: "krutoychel2004",
      ),
      const SizedBox(height: 24),
      _buildField(
        context,
        label: "Пароль",
        controller: _passwordController,
        hidden: _hidePassword,
        onHide: (value) {
          setState(() {
            _hidePassword = value;
          });
        },
        hint: "********",
      ),

      const SizedBox(height: 48),
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).primaryColorLight,
                ),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
              ),
              onPressed: _signOn,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Зарегистрироваться"),
              ),
            ),
          ),
        ],
      ),
      Spacer(),
    ],
  );

  Widget _buildLogin(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 70),
      Text(
        'Привет!',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: MediaQuery.of(context).size.width / 1.2,
        child: Text(
          'Заполните свои данные для входа в аккаунт или зарегестрируйтесь',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
      _buildField(
        context,
        label: "Логин",
        controller: _emailController,
        hint: "krutoychel2004",
      ),
      const SizedBox(height: 24),
      _buildField(
        context,
        label: "Пароль",
        controller: _passwordController,
        hidden: _hidePassword,
        onHide: (value) {
          setState(() {
            _hidePassword = value;
          });
        },
        hint: "********",
      ),

      const SizedBox(height: 48),
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).primaryColorLight,
                ),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
              ),
              onPressed: _signIn,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Войти"),
              ),
            ),
          ),
        ],
      ),
      Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          Text("Вы впервые?"),
          InkWell(
            onTap: () {
              setScreenState(_ScreenStates.regFirst);
            },
            child: Text(
              "Зарегистрироваться",
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildField(
    BuildContext context, {
    required String label,
    TextEditingController? controller,
    FocusNode? focusNode,
    void Function(bool value)? onHide,
    required String hint,
    bool? hidden,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(14)),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: hidden ?? false,

            decoration: InputDecoration(
              hint: Text(hint),
              filled: true,
              border: InputBorder.none,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              suffixIcon: onHide != null && hidden != null
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        hidden ? Icons.visibility : Icons.visibility_off,
                      ),
                      onTap: () => onHide(!hidden),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required String hint,
    required DateTime? selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final result = await showBoardDateTimeMultiPicker(
              context: context,
              pickerType: DateTimePickerType.date,
              startDate: selectedDate,
              minimumDate: DateTime(1900),
              maximumDate: DateTime.now(),
            );
            if (result != null) {
              onDateSelected(result.start);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
                        : hint,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selectedDate != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
