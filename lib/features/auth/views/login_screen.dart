import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  Future<void> _login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final me = await ref
          .read(authStateProvider.notifier)
          .login(_emailCtrl.text.trim(), _passwordCtrl.text);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (me == null) {
        AppSnackBar.error(context, 'No se pudo iniciar sesión.');
        return;
      }
      // GoRouter redirect handles navigation
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is AppException
          ? e.message
          : 'Error al iniciar sesión.';
      AppSnackBar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo / Header ──
                      Image.asset(
                            'assets/images/logo RenApp.jpg',
                            height: 180,
                            fit: BoxFit.contain,
                          )
                          .animate()
                          .fadeIn(duration: AppAnimations.slow)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: AppAnimations.slow,
                            curve: AppAnimations.defaultCurve,
                          ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // ── Email field ──
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(PhosphorIconsRegular.envelope),
                          hintText: 'tu@email.com',
                        ),
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Email requerido';
                          if (!_isValidEmail(v)) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Password field ──
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(PhosphorIconsRegular.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? PhosphorIconsRegular.eye
                                  : PhosphorIconsRegular.eyeSlash,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _isLoading ? null : _login(),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.trim().isEmpty) return 'Contraseña requerida';
                          if (v.length < 8) {
                            return 'Debe tener al menos 8 caracteres';
                          }
                          if (v.length > 72) return 'Máximo 72 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Submit button ──
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(PhosphorIconsRegular.signIn),
                          label: Text(
                            _isLoading ? 'Iniciando...' : 'Iniciar sesión',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Register buttons ──
                      const Divider(height: 32),
                      Text(
                        '¿Eres nuevo?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () => context.push(
                                        AppRoutes.registerPatient,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg,
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          PhosphorIcon(
                                            PhosphorIconsDuotone.user,
                                            size: 28,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Paciente',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Divider(
                                        color: scheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                        height: 1,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Crear cuenta de Paciente',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () => context.push(
                                        AppRoutes.registerDoctor,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg,
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          PhosphorIcon(
                                            PhosphorIconsDuotone.stethoscope,
                                            size: 28,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Médico',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Divider(
                                        color: scheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                        height: 1,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Crear cuenta de Médico',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
