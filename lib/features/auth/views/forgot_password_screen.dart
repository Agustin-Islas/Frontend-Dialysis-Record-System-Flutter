import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/utils/auth_exception_mapper.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailCtrl.text.trim();
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Código de recuperación enviado. Revisa tu correo.',
      );

      // Go to OTP verification screen passing type and next route
      context.push(
        '/verify-otp',
        extra: {
          'email': email,
          'type': OtpType.recovery,
          'onSuccessRoute': '/update-password',
        },
      );
    } catch (e) {
      if (mounted) {
        final errorMsg = AuthExceptionMapper.mapException(
          e,
          fallbackMessage: 'No se pudo enviar el código de recuperación.',
        );
        AppSnackBar.error(context, errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        PhosphorIconsRegular.lockKey,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '¿Olvidaste tu contraseña?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Ingresa tu correo electrónico y te enviaremos un código para recuperar el acceso a tu cuenta.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El correo es requerido';
                          }
                          if (!value.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _sendRecoveryCode(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _isLoading ? null : _sendRecoveryCode,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enviar código'),
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
