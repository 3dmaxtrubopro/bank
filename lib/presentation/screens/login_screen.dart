import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

final _usernameProvider = StateProvider<String>((ref) => 'alex.morgan');
final _passwordProvider = StateProvider<String>((ref) => 'ubs-secure');
final _biometricEnabledProvider = StateProvider<bool>((ref) => true);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final username = ref.watch(_usernameProvider);
    final password = ref.watch(_passwordProvider);
    final biometricsEnabled = ref.watch(_biometricEnabledProvider);
    final biometricAvailability = ref.watch(biometricAvailabilityProvider);
    final biometricsAvailable = biometricAvailability.valueOrNull?.isAvailable ?? false;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!context.mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);

      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.primary,
              content: Text(
                next.errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
      }

      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        context.go('/');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: AppLayout.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'UBS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Private Banking',
                    style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text('Sign in', style: theme.textTheme.displayLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Secure access with password sign-in and biometric verification.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Credentials', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 20),
                          TextFormField(
                            initialValue: username,
                            enabled: !authState.isProcessing,
                            decoration: const InputDecoration(
                              labelText: 'Client ID',
                              hintText: 'alex.morgan',
                            ),
                            onChanged: (value) {
                              ref.read(_usernameProvider.notifier).state = value;
                              ref.read(authProvider.notifier).clearError();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: password,
                            enabled: !authState.isProcessing,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter password',
                            ),
                            onChanged: (value) {
                              ref.read(_passwordProvider.notifier).state = value;
                              ref.read(authProvider.notifier).clearError();
                            },
                          ),
                          if (biometricAvailability.hasValue) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: AppLayout.inputRadius,
                                border: Border.all(color: colorScheme.outline),
                                color: colorScheme.surface,
                              ),
                              child: SwitchListTile.adaptive(
                                value: biometricsAvailable && biometricsEnabled,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Use biometrics'),
                                subtitle: Text(
                                  biometricsAvailable
                                      ? 'Use local biometric authentication'
                                      : 'Biometrics are unavailable on this device',
                                ),
                                onChanged: (!authState.isProcessing && biometricsAvailable)
                                    ? (value) {
                                        ref.read(_biometricEnabledProvider.notifier).state = value;
                                      }
                                    : null,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                           FilledButton(
                             onPressed: authState.isProcessing
                                 ? null
                                 : () {
                                    ref.read(authProvider.notifier).signIn(
                                          username: username,
                                          password: password,
                                          useBiometrics: biometricsAvailable && biometricsEnabled,
                                        );
                                  },
                            child: authState.isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Sign in'),
                          ),
                          if (biometricsAvailable) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: authState.isProcessing
                                  ? null
                                  : () {
                                      ref.read(authProvider.notifier).authenticateOnlyBiometrics();
                                    },
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Sign in with biometrics'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorScheme.outline),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Secure access', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 6),
                                Text(
                                  'Use the test credentials and biometric authentication where supported on your device.',
                                  style: theme.textTheme.bodyMedium,
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
          ),
        ),
      ),
    );
  }
}
