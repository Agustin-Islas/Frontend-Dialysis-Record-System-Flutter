import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/utils/auth_exception_mapper.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newPassword = _passwordCtrl.text;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Sign out after password update so they have to log in again with new credentials
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Contraseña actualizada exitosamente. Por favor, inicia sesión de nuevo.',
      );
      context.go('/login');
    } catch (e) {
      if (mounted) {
        final errorMsg = AuthExceptionMapper.mapException(
          e,
          fallbackMessage: 'No se pudo actualizar la contraseña.',
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
        title: const Text('Nueva contraseña'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.x),
          onPressed: () async {
            // If user cancels, sign them out since verifyOtp logged them in
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/login');
          },
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
                        PhosphorIconsRegular.shieldCheck,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Crea una nueva contraseña',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Tu nueva contraseña debe tener al menos 6 caracteres.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          prefixIcon: const Icon(PhosphorIconsRegular.lockKey),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es requerida';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: const Icon(PhosphorIconsRegular.lockKey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? PhosphorIconsRegular.eye
                                  : PhosphorIconsRegular.eyeSlash,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma tu contraseña';
                          }
                          if (value != _passwordCtrl.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _updatePassword(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _isLoading ? null : _updatePassword,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Actualizar contraseña'),
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
