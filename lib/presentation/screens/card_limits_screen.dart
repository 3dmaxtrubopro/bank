import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/card.dart';
import '../../providers/card_provider.dart';

class CardLimitsScreen extends ConsumerWidget {
  const CardLimitsScreen({required this.cardId, super.key});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(cardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Limites des cartes')),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: cardsAsync.when(
            data: (cards) {
              Card? card;
              for (final c in cards) {
                if (c.id == cardId) {
                  card = c;
                  break;
                }
              }
              if (card == null) {
                return Center(
                  child: Text(
                    'Card not found.',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              return ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            card.maskedNumber.substring(
                              card.maskedNumber.length - 2,
                            ),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.maskedNumber,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                card.holderName,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _LimitTile(
                    label: 'Limite mensuelle',
                    amount: "CHF 20'000.00",
                    availableText:
                        "Montant disponible pour ce mois: CHF 19'999.00",
                  ),
                  const _LimitTile(
                    label: 'Limite journalière pour les achats',
                    amount: "CHF 3'000.00",
                    availableText:
                        "Montant disponible aujourd'hui: CHF 3'000.00",
                  ),
                  const _LimitTile(
                    label: 'Limite journalière retraits d’espèces',
                    amount: "CHF 5'000.00",
                    availableText:
                        "Montant disponible aujourd'hui: CHF 5'000.00",
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Unable to load limits: $e',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.label,
    required this.amount,
    required this.availableText,
  });

  final String label;
  final String amount;
  final String availableText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(amount, style: theme.textTheme.titleLarge)),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
          const SizedBox(height: 6),
          Text(availableText, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
