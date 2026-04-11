import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../data/models/card.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/app_data_repository.dart';
import '../../providers/card_provider.dart';
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

class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

                                    final Transaction tx = Transaction(
                                      id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
                                      cardId: sourceCard.id,
                                      title: 'Transfer to ${recipient.trim()}',
                                      subtitle: note.trim(),
                                      amount: -parsedAmount,
                                      currency: sourceCard.currency,
                                      date: DateTime.now(),
                                      emoji: '💸',
                                    );

                                    await AppDataRepository.instance
                                        .addTransaction(tx);
                                    ref.invalidate(transactionProvider);

                                    if (!context.mounted) {
                                      return;
                                    }

                                    messenger
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          backgroundColor: colorScheme.primary,
                                          content: Text(
                                            'Transfer booked: ${currencyFormat.format(parsedAmount)} to ${recipient.trim()}.',
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
                            currencyFormat.format(sourceCard.balance),
                            style: theme.textTheme.headlineMedium,
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
