import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/security_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'routes.dart';

void main() {
  runApp(const ProviderScope(child: MobileBankApp()));
}

class MobileBankApp extends ConsumerStatefulWidget {
  const MobileBankApp({super.key});

  @override
  ConsumerState<MobileBankApp> createState() => _MobileBankAppState();
}

class _MobileBankAppState extends ConsumerState<MobileBankApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundAt = DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed || _backgroundAt == null) {
      return;
    }

    final authState = ref.read(authProvider);
    final securityState = ref.read(securityProvider);
    final elapsed = DateTime.now().difference(_backgroundAt!);

    if (authState.isAuthenticated &&
        securityState.hasPinCode &&
        !securityState.isLocked &&
        elapsed >= AppConstants.appLockTimeout) {
      ref.read(securityProvider.notifier).lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
