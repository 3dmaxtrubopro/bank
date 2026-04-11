import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../providers/security_provider.dart';

final _pinProvider = StateProvider<String>((ref) => '');
final _confirmPinProvider = StateProvider<String>((ref) => '');

class SetupPinScreen extends ConsumerWidget {
  const SetupPinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pin = ref.watch(_pinProvider);
    final confirmPin = ref.watch(_confirmPinProvider);
    final canSubmit = pin.length >= 4 && confirmPin.length >= 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up security PIN')),
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
                      Text(
                        'Protect your account',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a 4+ digit PIN to unlock the app quickly.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'New PIN',
                          hintText: 'Enter at least 4 digits',
                        ),
                        onChanged: (value) {
                          ref.read(_pinProvider.notifier).state = value.trim();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Confirm PIN',
                          hintText: 'Re-enter PIN',
                        ),
                        onChanged: (value) {
                          ref.read(_confirmPinProvider.notifier).state = value
                              .trim();
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: !canSubmit
                            ? null
                            : () {
                                final messenger = ScaffoldMessenger.of(context);
                                if (pin != confirmPin) {
                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        backgroundColor: colorScheme.primary,
                                        content: const Text(
                                          'PIN codes do not match.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  return;
                                }

                                ref
                                    .read(securityProvider.notifier)
                                    .setupPinCode(pin);
                                if (!context.mounted) {
                                  return;
                                }
                                context.go('/');
                              },
                        child: const Text('Save PIN'),
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
