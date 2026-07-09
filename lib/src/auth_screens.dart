import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loopController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    // Démo statique : pas d'appel réseau, aucune session locale à restaurer.
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GabPharmaLogoBadge(),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotationTransition(
                            turns: _loopController,
                            child: const Icon(
                              Icons.autorenew,
                              size: 20,
                              color: GabColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VÉRIFICATION DE LA SESSION...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: GabColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 16,
                        child: _SessionLoaderDots(controller: _loopController),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Text(
                      "Gab'Pharma © 2026",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: GabColors.muted.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: GabColors.muted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _GabPharmaLogoBadge extends StatelessWidget {
  const _GabPharmaLogoBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: GabColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_pharmacy_outlined,
                  size: 20,
                  color: GabColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: "Gab'",
                    style: TextStyle(
                      color: const Color(0xFF004F26),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  TextSpan(
                    text: 'Pharma',
                    style: TextStyle(
                      color: GabColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      );
}

class _SessionLoaderDots extends StatelessWidget {
  const _SessionLoaderDots({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final t = (controller.value + i * 0.2) % 1.0;
            final wave = 1 - (2 * t - 1).abs();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.55 + 0.45 * wave,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: GabColors.primary
                        .withValues(alpha: 0.4 + 0.6 * wave),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController(text: 'patient.demo@gabpharma.ga');
  final _password = TextEditingController(text: 'demonstration');
  bool _obscure = true;
  bool _rememberMe = false;
  bool _submitting = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pushNamed(context, '/verify');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: _GabPharmaLogoBadge(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Bon retour parmi nous',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: GabColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Veuillez vous connecter pour accéder à votre espace santé.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: GabColors.muted),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Identifiant (email/téléphone)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _identifier,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'nom@exemple.com',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Identifiant requis'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Mot de passe',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                  ),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Mot de passe requis'
                                        : null,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (value) => setState(
                                          () => _rememberMe = value ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(
                                        color: GabColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/password-reset'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      minimumSize: const Size(0, 44),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle:
                                          const TextStyle(fontSize: 13),
                                    ),
                                    child: const Text('Mot de passe oublié ?'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Se connecter'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas encore de compte ?',
                          style: TextStyle(color: GabColors.muted)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text("S'inscrire"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  static const _codeLength = 6;
  static const _demoCode = '123456';
  static const _resendSeconds = 59;
  static const _maxAttempts = 3;

  final _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  int _attempts = 0;
  bool _submitting = false;
  bool _expired = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _resendSeconds;
      _expired = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        setState(() => _expired = true);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final code = _enteredCode;
    if (code.length < _codeLength) {
      setState(() => _errorMessage = 'Saisissez les 6 chiffres du code.');
      return;
    }
    if (_attempts >= _maxAttempts) {
      setState(() => _errorMessage =
          'Trop de tentatives. Réessayez dans quelques minutes.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_timer == null || !_timer!.isActive) {
      // Countdown terminé : le code envoyé n'est plus valable.
      setState(() {
        _submitting = false;
        _attempts++;
        _errorMessage = 'Ce code a expiré. Demandez-en un nouveau.';
      });
      _clearCode();
      return;
    }
    if (code != _demoCode) {
      setState(() {
        _submitting = false;
        _attempts++;
        _errorMessage = _attempts >= _maxAttempts
            ? 'Trop de tentatives. Réessayez dans quelques minutes.'
            : 'Code invalide. Vérifiez et réessayez.';
      });
      _clearCode();
      return;
    }
    setState(() => _submitting = false);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: GabColors.primary),
                      ),
                    ),
                    Text(
                      "Gab'Pharma",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: GabColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.verified_user,
                            color: GabColors.primary, size: 34),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Vérification de sécurité',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: GabColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                              color: GabColors.muted, fontSize: 16),
                          children: [
                            const TextSpan(
                                text:
                                    'Entrez le code à 6 chiffres envoyé à votre numéro '),
                            TextSpan(
                              text: '(+241 ...)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: GabColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Démonstration : utilisez le code $_demoCode.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GabColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_codeLength, (i) {
                          final hasError = _errorMessage != null;
                          return SizedBox(
                            width: 44,
                            height: 56,
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: hasError
                                        ? GabColors.danger
                                        : GabColors.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: GabColors.primary, width: 1.6),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _errorMessage = null);
                                if (value.isNotEmpty && i < _codeLength - 1) {
                                  _focusNodes[i + 1].requestFocus();
                                } else if (value.isEmpty && i > 0) {
                                  _focusNodes[i - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GabColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule,
                              size: 16, color: GabColors.muted),
                          const SizedBox(width: 6),
                          if (_expired)
                            TextButton(
                              onPressed: _startCountdown,
                              child:
                                  const Text('Renvoyer le code maintenant'),
                            )
                          else
                            Text.rich(
                              TextSpan(
                                style:
                                    const TextStyle(color: GabColors.muted),
                                children: [
                                  const TextSpan(
                                      text: 'Renvoyer le code dans '),
                                  TextSpan(
                                    text:
                                        '0:${_secondsLeft.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: GabColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Vérifier'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false),
                        child: const Text('Utiliser un autre compte'),
                      ),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: GabColors.softGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield,
                                  size: 16, color: GabColors.muted),
                              SizedBox(width: 8),
                              Text(
                                'CONNEXION SÉCURISÉE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: GabColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  static const _otpLength = 6;
  static const _demoOtp = '123456';

  int _step = 0; // 0: identification, 1: code, 2: nouveau mdp, 3: succès
  final _identifier = TextEditingController();
  final _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _identifierError;
  String? _otpError;
  String? _confirmError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _newPassword.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _identifier.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newPassword.text.length >= 8;
  bool get _hasUpperAndDigit =>
      RegExp(r'[A-Z]').hasMatch(_newPassword.text) &&
      RegExp(r'[0-9]').hasMatch(_newPassword.text);
  bool get _hasSpecialChar =>
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-]''').hasMatch(_newPassword.text);
  bool get _passwordValid =>
      _hasMinLength && _hasUpperAndDigit && _hasSpecialChar;

  void _submitIdentifier() {
    if (_identifier.text.trim().isEmpty) {
      setState(() => _identifierError = 'Identifiant requis.');
      return;
    }
    setState(() {
      _identifierError = null;
      _step = 1;
    });
  }

  Future<void> _verifyOtp() async {
    if (_submitting) return;
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < _otpLength) {
      setState(() => _otpError = 'Saisissez les $_otpLength chiffres du code.');
      return;
    }
    setState(() {
      _submitting = true;
      _otpError = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (code != _demoOtp) {
      setState(() {
        _submitting = false;
        _otpError = 'Code invalide. Réessayez.';
      });
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes.first.requestFocus();
      return;
    }
    setState(() {
      _submitting = false;
      _step = 2;
    });
  }

  void _resetPassword() {
    if (!_passwordValid) {
      setState(() => _confirmError =
          'Le mot de passe ne respecte pas encore les règles de sécurité.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _confirmError = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _confirmError = null;
      _step = 3;
    });
  }

  void _goBack() {
    if (_step == 0 || _step == 3) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back,
                            color: GabColors.primary),
                      ),
                    ),
                    Text(
                      "Gab'Pharma",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              if (_step <= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  child: _StepperHeader(step: _step),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_step) {
                      0 => _buildIdentifyStep(),
                      1 => _buildOtpStep(),
                      2 => _buildNewPasswordStep(),
                      _ => _buildSuccessStep(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildIdentifyStep() => Column(
        key: const ValueKey('step-1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Identifiez-vous',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saisissez votre email ou votre numéro de téléphone pour recevoir un code de vérification.',
            style: TextStyle(color: GabColors.muted),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email ou Téléphone',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _identifier,
            decoration: InputDecoration(
              hintText: 'ex: +241 07 00 00 00',
              prefixIcon: const Icon(Icons.alternate_email),
              errorText: _identifierError,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitIdentifier,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continuer'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ],
      );

  Widget _buildOtpStep() => Column(
        key: const ValueKey('step-2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Code de vérification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Nous avons envoyé un code à $_otpLength chiffres à votre identifiant. Veuillez le saisir ci-dessous.',
            style: const TextStyle(color: GabColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            'Démonstration : utilisez le code $_demoOtp.',
            style: const TextStyle(
              color: GabColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (i) {
              final hasError = _otpError != null;
              return SizedBox(
                width: 44,
                height: 56,
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? GabColors.danger
                            : GabColors.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: GabColors.primary, width: 1.6),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _otpError = null);
                    if (value.isNotEmpty && i < _otpLength - 1) {
                      _otpFocusNodes[i + 1].requestFocus();
                    } else if (value.isEmpty && i > 0) {
                      _otpFocusNodes[i - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          if (_otpError != null) ...[
            const SizedBox(height: 12),
            Text(
              _otpError!,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: GabColors.danger, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 24),
          Column(
            children: [
              const Text("Vous n'avez pas reçu de code ?",
                  style: TextStyle(color: GabColors.muted)),
              TextButton(
                onPressed: () {
                  for (final c in _otpControllers) {
                    c.clear();
                  }
                  setState(() => _otpError = null);
                  _otpFocusNodes.first.requestFocus();
                },
                child: const Text('Renvoyer le code'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _verifyOtp,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Vérifier le code'),
          ),
        ],
      );

  Widget _buildNewPasswordStep() => Column(
        key: const ValueKey('step-3'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nouveau mot de passe',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "Créez un mot de passe robuste pour protéger votre compte Gab'Pharma.",
            style: TextStyle(color: GabColors.muted),
          ),
          const SizedBox(height: 24),
          const Text('Mot de passe',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassword,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                icon: Icon(_obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Confirmer le mot de passe',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
              errorText: _confirmError,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GabColors.softGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: GabColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Règles de sécurité :',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _RuleRow(label: 'Au moins 8 caractères', ok: _hasMinLength),
                _RuleRow(
                    label: 'Une majuscule et un chiffre',
                    ok: _hasUpperAndDigit),
                _RuleRow(
                    label: 'Un caractère spécial (!, @, #...)',
                    ok: _hasSpecialChar),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _resetPassword,
            child: const Text('Réinitialiser le mot de passe'),
          ),
        ],
      );

  Widget _buildSuccessStep() => Column(
        key: const ValueKey('step-success'),
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: GabColors.softGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: GabColors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Succès !',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GabColors.muted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false),
              child: const Text('Retour à la connexion'),
            ),
          ),
        ],
      );
}

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final activeIndex = step > 2 ? 2 : step;
    Widget dot(int index) {
      final active = index <= activeIndex;
      return Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? GabColors.primary : GabColors.softGreen,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : GabColors.muted,
          ),
        ),
      );
    }

    Widget line(int index) {
      final filled = index < activeIndex;
      return Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: filled ? GabColors.primary : GabColors.outlineVariant,
        ),
      );
    }

    return Row(
      children: [
        dot(0),
        line(0),
        dot(1),
        line(1),
        dot(2),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: ok ? GabColors.primary : GabColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: ok ? GabColors.ink : GabColors.muted)),
            ),
          ],
        ),
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _submitting = false;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final val = _password.text;
    var strength = 0;
    if (val.length > 5) strength++;
    if (val.length > 8 &&
        RegExp(r'[A-Z]').hasMatch(val) &&
        RegExp(r'[0-9]').hasMatch(val)) {
      strength++;
    }
    if (val.length > 10 && RegExp(r'[^A-Za-z0-9]').hasMatch(val)) strength++;
    if (val.length > 12) strength++;
    return strength;
  }

  Color get _strengthColor => switch (_passwordStrength) {
        1 => GabColors.danger,
        2 => const Color(0xFFB07E00),
        3 => GabColors.secondary,
        4 => GabColors.primary,
        _ => GabColors.outlineVariant,
      };

  String get _strengthLabel => switch (_passwordStrength) {
        1 => 'Très faible',
        2 => 'Moyen',
        3 => 'Fort',
        4 => 'Excellent',
        _ => 'Saisissez un mot de passe sécurisé',
      };

  void _showTermsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  bool _validate() {
    setState(() {
      _firstNameError =
          _firstName.text.trim().isEmpty ? 'Prénom requis' : null;
      _lastNameError = _lastName.text.trim().isEmpty ? 'Nom requis' : null;
      _emailError = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
              .hasMatch(_email.text.trim())
          ? null
          : 'E-mail invalide';
      _phoneError =
          _phone.text.trim().length < 7 ? 'Numéro de téléphone invalide' : null;
      _passwordError = _passwordStrength >= 2
          ? null
          : 'Mot de passe trop faible (minimum : moyen)';
      _confirmPasswordError = _confirmPassword.text != _password.text
          ? 'Les mots de passe ne correspondent pas.'
          : null;
      _termsError = _acceptTerms ? null : 'Acceptation requise';
    });
    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _termsError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la création du compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_firstName.text.trim()} ${_lastName.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_email.text.trim()),
            Text('+241 ${_phone.text.trim()}'),
            const SizedBox(height: 12),
            const Text(
              "Vous acceptez les conditions générales d'utilisation et la "
              'politique de confidentialité. Votre compte sera ensuite '
              'soumis à la vérification de sécurité (2FA).',
              style: TextStyle(color: GabColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Modifier'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pushNamed(context, '/verify');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: GabColors.primary),
                      ),
                    ),
                    Text(
                      "Gab'Pharma",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: GabColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rejoignez le réseau de santé leader au Gabon pour '
                        'gérer vos ordonnances et vos livraisons.',
                        style: TextStyle(color: GabColors.muted),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: 96,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      GabColors.softGreen,
                                      GabColors.primary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.local_pharmacy_outlined,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Prénom',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _firstName,
                                        decoration: InputDecoration(
                                          hintText: 'Ex: Jean',
                                          errorText: _firstNameError,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nom',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _lastName,
                                        decoration: InputDecoration(
                                          hintText: 'Ex: Moussavou',
                                          errorText: _lastNameError,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('E-mail',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'votre@email.com',
                                prefixIcon: const Icon(Icons.mail_outline),
                                errorText: _emailError,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Téléphone',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: GabColors.softGreen,
                                      border: Border.all(
                                          color: GabColors.outlineVariant),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(14),
                                        bottomLeft: Radius.circular(14),
                                      ),
                                    ),
                                    child: const Text('+241',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phone,
                                      keyboardType: TextInputType.phone,
                                      textAlignVertical: TextAlignVertical.center,
                                      decoration: InputDecoration(
                                        hintText: '07 00 00 00',
                                        errorText: _phoneError,
                                        border: OutlineInputBorder(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(14),
                                            bottomRight: Radius.circular(14),
                                          ),
                                          borderSide: const BorderSide(
                                              color: GabColors.outlineVariant),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(14),
                                            bottomRight: Radius.circular(14),
                                          ),
                                          borderSide: const BorderSide(
                                              color: GabColors.outlineVariant),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Mot de passe',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                                errorText: _passwordError,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(4, (i) {
                                final filled = i < _passwordStrength;
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        right: i < 3 ? 4 : 0),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: filled
                                          ? _strengthColor
                                          : GabColors.outlineVariant
                                              .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _strengthLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _passwordStrength == 0
                                    ? GabColors.muted
                                    : _strengthColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Confirmer le mot de passe',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _confirmPassword,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_outlined),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                  icon: Icon(_obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                                errorText: _confirmPasswordError,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (value) => setState(
                                        () => _acceptTerms = value ?? false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          color: GabColors.muted,
                                          fontSize: 13,
                                          height: 1.3),
                                      children: [
                                        const TextSpan(text: "J'accepte les "),
                                        TextSpan(
                                          text:
                                              "conditions générales d'utilisation",
                                          style: TextStyle(
                                            color: GabColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = _showTermsDialog,
                                        ),
                                        const TextSpan(text: ' et la '),
                                        TextSpan(
                                          text:
                                              'politique de confidentialité',
                                          style: TextStyle(
                                            color: GabColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = _showPrivacyPolicy,
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_termsError != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, left: 30),
                                child: Text(
                                  _termsError!,
                                  style: const TextStyle(
                                      color: GabColors.danger, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Créer mon compte'),
                                          SizedBox(width: 4),
                                          Icon(Icons.chevron_right, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Déjà inscrit ? Se connecter'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _TrustBadge(
                              icon: Icons.verified_user, label: 'Sécurisé'),
                          _TrustBadge(
                              icon: Icons.health_and_safety,
                              label: 'Santé Gabon'),
                          _TrustBadge(
                              icon: Icons.local_shipping, label: 'Livraison'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.6,
        child: Column(
          children: [
            Icon(icon, color: GabColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

class _TermsSection {
  const _TermsSection(this.title, this.body);

  final String title;
  final String body;
}

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const _sections = [
    _TermsSection(
      '1. Objet',
      "Gab'Pharma fournit un service numérique de mise en relation et "
          "d'orchestration entre patients, pharmacies, livreurs et "
          "partenaires. Gab'Pharma n'est pas une pharmacie et n'assure pas "
          'elle-même la dispensation.',
    ),
    _TermsSection(
      '2. Accès à la plateforme',
      'La consultation publique est libre. La réservation, le paiement et '
          'les espaces professionnels nécessitent un compte actif et des '
          'informations exactes.',
    ),
    _TermsSection(
      '3. Comptes utilisateurs',
      "L'utilisateur est responsable de la confidentialité de ses accès. "
          'Les comptes professionnels sont activés après validation par '
          "Gab'Pharma.",
    ),
    _TermsSection(
      '4. Réservations et paiements',
      "Une demande reste soumise à l'acceptation de la pharmacie et à la "
          'disponibilité réelle du stock. Les prix et frais sont présentés '
          'avant confirmation.',
    ),
    _TermsSection(
      '5. Livraison',
      'Les délais sont indicatifs et dépendent de la préparation, de la '
          "zone et de la disponibilité d'un livreur. Les incidents sont "
          'traités selon la procédure de support et de remboursement.',
    ),
    _TermsSection(
      '6. Responsabilités des partenaires',
      'La pharmacie reste responsable de la conformité des produits, de son '
          'stock et de la dispensation. Le livreur est responsable de la '
          'bonne exécution de la course qui lui est confiée.',
    ),
    _TermsSection(
      '7. Résiliation',
      "Un compte peut être suspendu ou clôturé en cas de fraude, d'abus, "
          "d'impayé ou de non-respect des obligations applicables.",
    ),
    _TermsSection(
      '8. Droit applicable',
      'Le droit applicable et la juridiction compétente seront précisés '
          'après validation juridique du dispositif au Gabon.',
    ),
  ];

  final _scrollController = ScrollController();
  final _sectionKeys = List.generate(_sections.length, (_) => GlobalKey());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: GabColors.primary),
                      ),
                    ),
                    Text(
                      "Gab'Pharma",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conditions générales de service',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: GabColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Les règles applicables aux réservations, paiements, '
                        'livraisons et relations avec les partenaires.',
                        style: TextStyle(color: GabColors.muted),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sommaire',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...List.generate(
                              _sections.length,
                              (i) => InkWell(
                                onTap: () => _scrollToSection(i),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    _sections[i].title,
                                    style: const TextStyle(
                                      color: GabColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GabColors.softGreen,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: GabColors.outlineVariant
                                  .withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: GabColors.secondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ce texte constitue une base de travail et '
                                'devra être validé juridiquement avant le '
                                'lancement commercial.',
                                style: TextStyle(
                                  color: GabColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < _sections.length; i++)
                        Padding(
                          key: _sectionKeys[i],
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sections[i].title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: GabColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _sections[i].body,
                                style: const TextStyle(
                                  color: GabColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const _sections = [
    _TermsSection(
      '1. Données collectées',
      'Nous collectons les informations nécessaires à la création du '
          'compte, à la réservation, au paiement, à la livraison, au '
          'support et aux obligations légales : identité, coordonnées, '
          'zone, affiliation déclarative, contenu des commandes et '
          'historique des opérations.',
    ),
    _TermsSection(
      '2. Utilisation des données',
      'Les données sont utilisées uniquement pour fournir la plateforme, '
          'sécuriser les accès, traiter les demandes, améliorer le service '
          "et produire des statistiques agrégées. L'historique des "
          "médicaments n'est pas utilisé à des fins de ciblage "
          'publicitaire.',
    ),
    _TermsSection(
      '3. Partage des données',
      'Chaque acteur reçoit uniquement les informations nécessaires à son '
          'intervention. Les assureurs disposent en V1 de statistiques '
          "agrégées et non d'un historique nominatif des médicaments.",
    ),
    _TermsSection(
      '4. Sécurité et conservation',
      'Les accès sont limités par rôle, les communications utilisent TLS '
          'et les actions sensibles sont auditées. Les durées de '
          'conservation sont documentées et les données devenues inutiles '
          'sont supprimées ou anonymisées.',
    ),
    _TermsSection(
      '5. Vos droits',
      "Vous pouvez demander l'accès, la rectification, l'export ou la "
          'suppression de vos données, dans les limites des obligations '
          'légales applicables.',
    ),
    _TermsSection(
      '6. Cookies',
      'Les cookies strictement nécessaires permettent le fonctionnement et '
          'la sécurité du service. Les traceurs facultatifs nécessitent un '
          'consentement distinct.',
    ),
    _TermsSection(
      '7. Contact',
      'Pour toute question relative à vos données : privacy@gabpharma.ga.',
    ),
  ];

  final _scrollController = ScrollController();
  final _sectionKeys = List.generate(_sections.length, (_) => GlobalKey());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GabColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: GabColors.primary),
                      ),
                    ),
                    Text(
                      "Gab'Pharma",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GabColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: GabColors.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Politique de confidentialité',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: GabColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dernière mise à jour : 1er juillet 2026. Découvrez '
                        "comment Gab'Pharma protège et utilise vos "
                        'informations.',
                        style: TextStyle(color: GabColors.muted),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sommaire',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...List.generate(
                              _sections.length,
                              (i) => InkWell(
                                onTap: () => _scrollToSection(i),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    _sections[i].title,
                                    style: const TextStyle(
                                      color: GabColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GabColors.softGreen,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: GabColors.outlineVariant
                                  .withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 18, color: GabColors.secondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Protection dès la conception. Une '
                                'réservation de médicament peut révéler '
                                'indirectement une information de santé. '
                                "Gab'Pharma lui applique donc un niveau de "
                                'protection renforcé.',
                                style: TextStyle(
                                  color: GabColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < _sections.length; i++)
                        Padding(
                          key: _sectionKeys[i],
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sections[i].title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: GabColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _sections[i].body,
                                style: const TextStyle(
                                  color: GabColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
