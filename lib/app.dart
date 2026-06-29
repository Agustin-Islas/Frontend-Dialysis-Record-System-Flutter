import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/design/design.dart';
import 'core/router/app_router.dart';

/// Root widget of the application.
///
/// Uses [MaterialApp.router] with GoRouter for declarative navigation,
/// the design system theme, and Responsive Framework breakpoints.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RenApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
        child: child!,
      ),
    );
  }
}
