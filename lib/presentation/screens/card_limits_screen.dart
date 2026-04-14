import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_icons.dart';
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
    final limits = ref.watch(cardLimitsByIdProvider(cardId));

    return Scaffold(
      appBar: AppBar(title: const Text('Limites des cartes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              final resolvedCard = card;

              return ListView(
                children: [
                  _CardHeader(card: resolvedCard),
                  const SizedBox(height: 12),
                  _LimitRow(
                    label: 'Limite mensuelle',
                    amount: _formatMoney(
                      limits.monthlyLimit,
                      resolvedCard.currency,
                    ),
                    availableText:
                        'Montant disponible pour ce mois: ${_formatMoney(limits.monthlyAvailable, resolvedCard.currency)}',
                    onTap: () => _editLimit(
                      context: context,
                      ref: ref,
                      card: resolvedCard,
                      current: limits,
                      type: _LimitType.monthly,
                    ),
                  ),
                  _LimitRow(
                    label: 'Limite journalière pour les achats',
                    amount: _formatMoney(
                      limits.dailyPurchaseLimit,
                      resolvedCard.currency,
                    ),
                    availableText:
                        'Montant disponible aujourd’hui: ${_formatMoney(limits.dailyPurchaseAvailable, resolvedCard.currency)}',
                    onTap: () => _editLimit(
                      context: context,
                      ref: ref,
                      card: resolvedCard,
                      current: limits,
                      type: _LimitType.dailyPurchase,
                    ),
                  ),
                  _LimitRow(
                    label: 'Limite journalière pour les retraits d’espèces',
                    amount: _formatMoney(
                      limits.dailyCashLimit,
                      resolvedCard.currency,
                    ),
                    availableText:
                        'Montant disponible aujourd’hui: ${_formatMoney(limits.dailyCashAvailable, resolvedCard.currency)}',
                    onTap: () => _editLimit(
                      context: context,
                      ref: ref,
                      card: resolvedCard,
                      current: limits,
                      type: _LimitType.dailyCash,
                    ),
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

enum _LimitType { monthly, dailyPurchase, dailyCash }

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.card});

  final Card card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              card.maskedNumber.substring(card.maskedNumber.length - 2),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.maskedNumber.replaceFirst('**** ', '5461 31XX XXXX '),
                  style: theme.textTheme.titleMedium,
                ),
                Text(card.holderName, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.label,
    required this.amount,
    required this.availableText,
    required this.onTap,
  });

  final String label;
  final String amount;
  final String availableText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(amount, style: theme.textTheme.headlineSmall),
                ),
                const Icon(AppIcons.chevronDown),
              ],
            ),
            const SizedBox(height: 4),
            Text(availableText, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editLimit({
  required BuildContext context,
  required WidgetRef ref,
  required Card card,
  required CardLimitsState current,
  required _LimitType type,
}) async {
  final currentValue = switch (type) {
    _LimitType.monthly => current.monthlyLimit,
    _LimitType.dailyPurchase => current.dailyPurchaseLimit,
    _LimitType.dailyCash => current.dailyCashLimit,
  };
  final usedValue = switch (type) {
    _LimitType.monthly => current.monthlyUsed,
    _LimitType.dailyPurchase => current.dailyPurchaseUsed,
    _LimitType.dailyCash => current.dailyCashUsed,
  };
  final label = switch (type) {
    _LimitType.monthly => 'Limite mensuelle',
    _LimitType.dailyPurchase => 'Limite journalière achats',
    _LimitType.dailyCash => 'Limite journalière retraits',
  };

  final controller = TextEditingController(
    text: currentValue.toStringAsFixed(2),
  );
  final value = await showDialog<double>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text(label),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Montant',
            prefixText: '${card.currency} ',
            helperText: 'Doit être ≥ ${_formatMoney(usedValue, card.currency)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final next = _parseAmount(controller.text);
              if (next == null || next <= 0 || next < usedValue) {
                ScaffoldMessenger.of(dialogContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Valeur invalide. Entrez un montant ≥ ${_formatMoney(usedValue, card.currency)}.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                return;
              }
              Navigator.of(dialogContext).pop(next);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      );
    },
  );
  controller.dispose();

  if (value == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  final monthly = type == _LimitType.monthly ? value : current.monthlyLimit;
  final dailyPurchase = type == _LimitType.dailyPurchase
      ? value
      : current.dailyPurchaseLimit;
  final dailyCash = type == _LimitType.dailyCash
      ? value
      : current.dailyCashLimit;

  if (dailyPurchase > monthly || dailyCash > monthly) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Les limites journalières ne peuvent pas dépasser la limite mensuelle.',
          ),
        ),
      );
    return;
  }

  final saved = ref
      .read(cardLimitsProvider.notifier)
      .updateLimits(
        card.id,
        monthlyLimit: monthly,
        dailyPurchaseLimit: dailyPurchase,
        dailyCashLimit: dailyCash,
      );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Limite mise à jour.'
              : 'Impossible de mettre à jour la limite.',
        ),
      ),
    );
}

String _formatMoney(double amount, String currency) {
  final formatter = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: '$currency ',
    decimalDigits: 2,
    customPattern: "¤ #,##0.00",
  );
  return formatter.format(amount).replaceAll(',', "'");
}

double? _parseAmount(String value) {
  final normalized = value.replaceAll("'", '').replaceAll(',', '.').trim();
  return double.tryParse(normalized);
}
