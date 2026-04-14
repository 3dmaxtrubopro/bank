import 'dart:async';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../data/models/card.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/app_data_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/transaction_provider.dart';

final _transferAmountProvider = StateProvider<String>((ref) => '1250.00');
final _transferRecipientProvider = StateProvider<String>(
  (ref) => 'Zurich Family Office',
);
final _transferIbanProvider = StateProvider<String>(
  (ref) => 'CH56 0483 5012 3498 7000 9',
);
final _transferNoteProvider = StateProvider<String>(
  (ref) => 'Consulting retainer',
);

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({
    this.initialRecipient,
    this.initialIban,
    this.initialNote,
    this.initialAmount,
    super.key,
  });

  final String? initialRecipient;
  final String? initialIban;
  final String? initialNote;
  final String? initialAmount;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialRecipient != null &&
          widget.initialRecipient!.trim().isNotEmpty) {
        ref.read(_transferRecipientProvider.notifier).state = widget
            .initialRecipient!
            .trim();
      }
      if (widget.initialIban != null && widget.initialIban!.trim().isNotEmpty) {
        ref.read(_transferIbanProvider.notifier).state = widget.initialIban!
            .trim();
      }
      if (widget.initialNote != null && widget.initialNote!.trim().isNotEmpty) {
        ref.read(_transferNoteProvider.notifier).state = widget.initialNote!
            .trim();
      }
      if (widget.initialAmount != null &&
          widget.initialAmount!.trim().isNotEmpty) {
        ref.read(_transferAmountProvider.notifier).state = widget.initialAmount!
            .trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AsyncValue<List<Card>> cardsAsync = ref.watch(cardsProvider);
    final Card? selectedCard = ref.watch(selectedCardProvider);
    final String amount = ref.watch(_transferAmountProvider);
    final String recipient = ref.watch(_transferRecipientProvider);
    final String iban = ref.watch(_transferIbanProvider);
    final String note = ref.watch(_transferNoteProvider);
    final AsyncValue<List<Transaction>> transactionAsync = ref.watch(
      transactionProvider,
    );
    final bool isSubmitting =
        transactionAsync.isRefreshing || transactionAsync.isReloading;

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer funds')),
      body: SafeArea(
        child: cardsAsync.when(
          data: (List<Card> cards) {
            if (cards.isEmpty) {
              return const Center(child: Text('No cards available.'));
            }

            final Card sourceCard = selectedCard ?? _primaryCard(cards);
            final NumberFormat currencyFormat = NumberFormat.currency(
              locale: AppConstants.currencyLocale,
              symbol: '${sourceCard.currency} ',
              decimalDigits: 2,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: AppLayout.screenPadding,
                  children: <Widget>[
                    Text(
                      'Domestic transfer',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a payment from the selected account and add it to recent activity.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    _FlatSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Source account',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            initialValue: sourceCard.id,
                            items: cards
                                .map(
                                  (Card card) => DropdownMenuItem<String>(
                                    value: card.id,
                                    child: Text(
                                      '${card.label} - ${card.maskedNumber}',
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (String? value) {
                              if (value == null) {
                                return;
                              }
                              ref.read(selectedCardIdProvider.notifier).state =
                                  value;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Debit from',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: recipient,
                            decoration: const InputDecoration(
                              labelText: 'Recipient',
                            ),
                            onChanged: (String value) {
                              ref
                                      .read(_transferRecipientProvider.notifier)
                                      .state =
                                  value;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: iban,
                            decoration: const InputDecoration(
                              labelText: 'Recipient IBAN',
                            ),
                            onChanged: (String value) {
                              ref.read(_transferIbanProvider.notifier).state =
                                  value;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              suffixText: sourceCard.currency,
                            ),
                            onChanged: (String value) {
                              ref.read(_transferAmountProvider.notifier).state =
                                  value;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: note,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Reference',
                            ),
                            onChanged: (String value) {
                              ref.read(_transferNoteProvider.notifier).state =
                                  value;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);
                                    final double? parsedAmount =
                                        double.tryParse(
                                          amount.replaceAll(',', '.'),
                                        );

                                    if (recipient.trim().isEmpty ||
                                        iban.trim().isEmpty ||
                                        note.trim().isEmpty ||
                                        parsedAmount == null ||
                                        parsedAmount <= 0) {
                                      messenger
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                colorScheme.primary,
                                            content: const Text(
                                              'Fill all transfer fields with valid values.',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      return;
                                    }

                                    final bool confirmed =
                                        await _confirmTransfer(
                                          context: context,
                                          sourceCard: sourceCard,
                                          recipient: recipient.trim(),
                                          iban: iban.trim(),
                                          note: note.trim(),
                                          amount: parsedAmount,
                                          currencyFormat: currencyFormat,
                                        );
                                    if (!confirmed) {
                                      return;
                                    }
                                    if (!context.mounted) {
                                      return;
                                    }

                                    final bool stepUpPassed =
                                        await _authorizeLargeTransfer(
                                          context: context,
                                          ref: ref,
                                          amount: parsedAmount,
                                          currency: sourceCard.currency,
                                        );
                                    if (!stepUpPassed) {
                                      return;
                                    }

                                    final Transaction tx = Transaction(
                                      id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
                                      cardId: sourceCard.id,
                                      title: 'Transfer to ${recipient.trim()}',
                                      subtitle: note.trim(),
                                      amount: -parsedAmount,
                                      currency: sourceCard.currency,
                                      date: DateTime.now(),
                                      emoji: '💸',
                                      status: TransactionStatus.pending,
                                    );

                                    await AppDataRepository.instance
                                        .addTransaction(tx);
                                    ref
                                      ..invalidate(transactionProvider)
                                      ..invalidate(cardProvider);
                                    unawaited(
                                      Future<void>.delayed(
                                        AppConstants.pendingSettlementDelay +
                                            const Duration(seconds: 1),
                                        () {
                                          if (!mounted) {
                                            return;
                                          }
                                          ref
                                            ..invalidate(transactionProvider)
                                            ..invalidate(cardProvider);
                                        },
                                      ),
                                    );

                                    if (!context.mounted) {
                                      return;
                                    }

                                    messenger
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          backgroundColor: colorScheme.primary,
                                          content: Text(
                                            'Transfer sent: ${currencyFormat.format(parsedAmount)} to ${recipient.trim()}. Initial status: Pending.',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    context.go('/transactions');
                                  },
                            child: const Text('Submit transfer'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FlatSection(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Available balance',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(sourceCard.availableBalance),
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Booked: ${currencyFormat.format(sourceCard.bookedBalance)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Submitted transfers appear in the recent activity list for the selected card.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) {
            return Center(child: Text('Unable to load cards: $error'));
          },
        ),
      ),
    );
  }

  Card _primaryCard(List<Card> cards) {
    for (final Card card in cards) {
      if (card.isPrimary) {
        return card;
      }
    }
    return cards.first;
  }
}

class _FlatSection extends StatelessWidget {
  const _FlatSection({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppLayout.cardRadius,
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

Future<bool> _confirmTransfer({
  required BuildContext context,
  required Card sourceCard,
  required String recipient,
  required String iban,
  required String note,
  required double amount,
  required NumberFormat currencyFormat,
}) async {
  final bool? result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final theme = Theme.of(sheetContext);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review transfer', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            _ReviewRow(
              label: 'From',
              value: '${sourceCard.label} ${sourceCard.maskedNumber}',
            ),
            _ReviewRow(label: 'Recipient', value: recipient),
            _ReviewRow(label: 'IBAN', value: iban),
            _ReviewRow(label: 'Reference', value: note),
            _ReviewRow(label: 'Amount', value: currencyFormat.format(amount)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: theme.textTheme.titleMedium)),
        ],
      ),
    );
  }
}

Future<bool> _authorizeLargeTransfer({
  required BuildContext context,
  required WidgetRef ref,
  required double amount,
  required String currency,
}) async {
  if (amount < AppConstants.stepUpAuthAmountThreshold) {
    return true;
  }

  final securityState = ref.read(securityProvider);
  final canUseBiometrics =
      (await ref.read(authProvider.notifier).getBiometricAvailability())
          .isAvailable;
  final hasPin = securityState.hasPinCode;

  if (!hasPin && !canUseBiometrics) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }

  final messenger = ScaffoldMessenger.of(context);
  final method = await _chooseStepUpMethod(
    context: context,
    canUseBiometrics: canUseBiometrics,
    hasPin: hasPin,
    amount: amount,
    currency: currency,
  );

  if (method == null) {
    return false;
  }

  if (method == _StepUpMethod.biometrics) {
    final ok = await ref
        .read(authProvider.notifier)
        .authenticateBiometricsForAction(
          reason:
              'Approve high-value transfer of $currency ${amount.toStringAsFixed(2)}',
        );
    if (!context.mounted) {
      return false;
    }
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric verification failed. Transfer was not submitted.',
            ),
          ),
        );
    }
    return ok;
  }
  if (!context.mounted) {
    return false;
  }

  final pin = await _promptStepUpPin(context);
  if (pin == null) {
    return false;
  }

  final ok = ref.read(securityProvider.notifier).verifyPinCode(pin);
  if (!ok) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Transfer was not submitted.'),
        ),
      );
  }
  return ok;
}

Future<_StepUpMethod?> _chooseStepUpMethod({
  required BuildContext context,
  required bool canUseBiometrics,
  required bool hasPin,
  required double amount,
  required String currency,
}) async {
  if (canUseBiometrics && !hasPin) {
    return _StepUpMethod.biometrics;
  }
  if (!canUseBiometrics && hasPin) {
    return _StepUpMethod.pin;
  }

  final _StepUpMethod? method = await showModalBottomSheet<_StepUpMethod>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final theme = Theme.of(sheetContext);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional verification required',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Transfers above $currency ${AppConstants.stepUpAuthAmountThreshold.toStringAsFixed(0)} require extra approval.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.biometrics),
              title: const Text('Use biometrics'),
              subtitle: Text('Approve $currency ${amount.toStringAsFixed(2)}'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_StepUpMethod.biometrics),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.pin),
              title: const Text('Use PIN'),
              subtitle: const Text('Enter your security PIN'),
              onTap: () => Navigator.of(sheetContext).pop(_StepUpMethod.pin),
            ),
          ],
        ),
      );
    },
  );

  return method;
}

Future<String?> _promptStepUpPin(BuildContext context) async {
  String pin = '';
  final String? value = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm with PIN'),
            content: TextFormField(
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Security PIN'),
              onChanged: (v) {
                setState(() {
                  pin = v.trim();
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: pin.length < 4
                    ? null
                    : () => Navigator.of(dialogContext).pop(pin),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
  return value;
}

enum _StepUpMethod { biometrics, pin }
