import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';

final _unlockPinProvider = StateProvider<String>((ref) => '');

class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final securityState = ref.watch(securityProvider);
    final pin = ref.watch(_unlockPinProvider);
    final availability = ref.watch(biometricAvailabilityProvider);
    final canUseBiometrics = availability.valueOrNull?.isAvailable ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock app')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: AppLayout.screenPadding,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session locked', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your PIN to continue.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (securityState.failedAttempts > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Failed attempts: ${securityState.failedAttempts}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          hintText: 'Enter security PIN',
                        ),
                        onChanged: (value) {
                          ref.read(_unlockPinProvider.notifier).state = value
                              .trim();
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: pin.length < 4
                            ? null
                            : () {
                                final unlocked = ref
                                    .read(securityProvider.notifier)
                                    .unlockWithPinCode(pin);
                                if (!unlocked) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        backgroundColor: colorScheme.primary,
                                        content: const Text(
                                          'Incorrect PIN. Please try again.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  return;
                                }

                                if (!context.mounted) {
                                  return;
                                }
                                context.go('/');
                              },
                        child: const Text('Unlock'),
                      ),
                      if (canUseBiometrics) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final didAuthenticate = await ref
                                .read(authProvider.notifier)
                                .authenticateBiometricsForAction(
                                  reason: 'Use biometrics to unlock the app',
                                );
                            if (!didAuthenticate) {
                              return;
                            }
                            ref
                                .read(securityProvider.notifier)
                                .unlockAfterBiometric();
                            if (!context.mounted) {
                              return;
                            }
                            context.go('/');
                          },
                          icon: const Icon(AppIcons.biometrics),
                          label: const Text('Unlock with biometrics'),
                        ),
                      ],
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
