import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/utils/auth_exception_mapper.dart';
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
      // Login normal con correo y contraseña
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Try to sync with the backend explicitly to catch connection errors
      try {
        await ref.read(authStateProvider.notifier).refresh();
        final authState = ref.read(authStateProvider);
        if (authState.hasError) {
          throw authState.error!;
        }
      } catch (e) {
        // Sign out from Supabase if backend is unreachable or user not found
        await Supabase.instance.client.auth.signOut();
        throw Exception('Servidor no disponible. No se pudo cargar el perfil.');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (kDebugMode) debugPrint('SUPABASE ERROR: $e');
      final errorMsg = AuthExceptionMapper.mapException(
        e,
        fallbackMessage: 'Error al iniciar sesión. Inténtalo nuevamente.',
      );
      AppSnackBar.error(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo / Brand Header (Fuera de la tarjeta) ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/new_icon_renapp_squared.jpg',
                              height: 80, // Aumentado para mayor presencia
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Text(
                          'RenApp',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F3057),
                                letterSpacing: -1.2,
                                height: 1.0,
                              ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: AppAnimations.slow)
                        .slideY(
                          begin: -0.1,
                          end: 0,
                          duration: AppAnimations.slow,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Tarjeta de Login ──
                    Card(
                      elevation: 0,
                      color: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(
                            'Bienvenido',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Ingresa a tu cuenta para continuar',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // ── Email field ──
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(PhosphorIconsRegular.envelope),
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
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(PhosphorIconsRegular.lockKey),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _isLoading ? null : _login(),
                          ),

                          // ── Forgot Password ──
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(color: scheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // ── Submit button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
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
                                _isLoading
                                    ? 'Iniciando sesión...'
                                    : 'Ingresar a la app',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Register buttons ──
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿No tienes cuenta?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.push(AppRoutes.registerPatient),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Paciente'),
                              ),
                              Text(
                                'o',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.push(AppRoutes.registerDoctor),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Profesional'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ), // <-- Cierra Card
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}
