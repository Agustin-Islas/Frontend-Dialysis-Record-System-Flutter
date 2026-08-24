import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';

/// Pantalla amigable para rutas no encontradas o accesos no autorizados.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Denegado / No encontrado'),
        centerTitle: true,
      ),
      body: Center(
        child: AppEmptyState(
          icon: PhosphorIconsRegular.shieldWarning,
          message: 'No pudimos encontrar la pantalla que buscas, o no tienes permisos para acceder a ella.',
          actionLabel: 'Volver al inicio',
          onAction: () => context.go('/'),
        ),
      ),
    );
  }
}
