import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/card.dart';
import '../../data/models/transaction.dart';
import '../../providers/card_provider.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/transaction_provider.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({required this.cardId, super.key});

  final String cardId;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCardIdProvider.notifier).state = widget.cardId;
    });
  }

  void _showPreviewAction(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label is available in this preview build only.'),
        ),
      );
  }

  void _toggleCardFrozen(BuildContext context, Card card) {
    ref.read(cardSettingsProvider.notifier).toggleCardFrozen(card.id);
    final nextState = ref.read(cardSettingsByIdProvider(card.id));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            nextState.isCardFrozen
                ? 'Card has been frozen.'
                : 'Card has been unfrozen.',
          ),
        ),
      );
  }

  String _formatMoney(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '$currency ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(cardProvider);
    final selectedCardId = ref.watch(selectedCardIdProvider);
    final transactions = ref.watch(selectedCardTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(cardLabelFromId(widget.cardId)),
        actions: [
          IconButton(
            onPressed: () => _showPreviewAction(context, 'Edit card details'),
            icon: const Icon(AppIcons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: cardsAsync.when(
          data: (List<Card> cards) {
            final Card? card = _resolveCard(cards, selectedCardId);
            if (card == null) {
              return _EmptyState(cardId: widget.cardId);
            }
            final settings = ref.watch(cardSettingsByIdProvider(card.id));
            final limits = ref.watch(cardLimitsByIdProvider(card.id));

            final List<Transaction> cardTransactions = _filterTransactions(
              transactions,
              card.id,
            );

            return ListView(
              padding: AppLayout.screenPadding,
              children: [
                _HeroCard(
                  card: card,
                  onShowDetails: () =>
                      _showPreviewAction(context, 'Full card number'),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Actions',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundAction(
                        icon: AppIcons.lock,
                        label: settings.isCardFrozen ? 'Bloquée' : 'Bloquer',
                        selected: settings.isCardFrozen,
                        onTap: () => _toggleCardFrozen(context, card),
                      ),
                      _RoundAction(
                        icon: AppIcons.card,
                        label: 'Remplacer',
                        onTap: () =>
                            _showPreviewAction(context, 'Replace card'),
                      ),
                      _RoundAction(
                        icon: AppIcons.pin,
                        label: 'NIP',
                        onTap: () =>
                            _showPreviewAction(context, 'Replacement PIN'),
                      ),
                      _RoundAction(
                        icon: AppIcons.eye,
                        label: 'Détails',
                        onTap: () =>
                            _showPreviewAction(context, 'Card details'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Apple Pay',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activez cette carte pour Apple Pay.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showPreviewAction(context, 'Add to Apple Wallet'),
                        icon: const Icon(AppIcons.apple),
                        label: const Text('Ajouter à Cartes d’Apple'),
                      ),
                      const SizedBox(height: 18),
                      Text('Click to Pay', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Click to Pay offre le confort du sans contact en ligne.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: settings.isContactlessEnabled
                            ? null
                            : () {
                                ref
                                    .read(cardSettingsProvider.notifier)
                                    .setContactlessEnabled(card.id, true);
                              },
                        icon: const Icon(AppIcons.contactless),
                        label: Text(
                          settings.isContactlessEnabled ? 'Activé' : 'Activer',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Paramètres de la carte',
                  child: Column(
                    children: [
                      _SettingRow(
                        title: 'Limites des cartes',
                        subtitle:
                            'Montant mensuel: ${_formatMoney(limits.monthlyLimit, card.currency)}',
                        onTap: () => context.go('/card/${card.id}/limits'),
                        trailing: const Icon(AppIcons.chevronRight),
                      ),
                      const Divider(),
                      _SettingRow(
                        title: '3-D Secure',
                        subtitle: settings.is3DSecureEnabled
                            ? 'Activé pour les achats en ligne'
                            : 'Désactivé pour les achats en ligne',
                        onTap: () {
                          ref
                              .read(cardSettingsProvider.notifier)
                              .set3DSecureEnabled(
                                card.id,
                                !settings.is3DSecureEnabled,
                              );
                        },
                        trailing: Switch(
                          value: settings.is3DSecureEnabled,
                          onChanged: (value) {
                            ref
                                .read(cardSettingsProvider.notifier)
                                .set3DSecureEnabled(card.id, value);
                          },
                        ),
                      ),
                      const Divider(),
                      _SettingRow(
                        title: 'Paiement sans contact',
                        subtitle: settings.isContactlessEnabled
                            ? 'Paiement sans NIP pour petits montants'
                            : 'Paiement sans contact désactivé',
                        onTap: () {
                          ref
                              .read(cardSettingsProvider.notifier)
                              .setContactlessEnabled(
                                card.id,
                                !settings.isContactlessEnabled,
                              );
                        },
                        trailing: Switch(
                          value: settings.isContactlessEnabled,
                          onChanged: (value) {
                            ref
                                .read(cardSettingsProvider.notifier)
                                .setContactlessEnabled(card.id, value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Activité récente',
                  trailing: Text(
                    '${cardTransactions.length} opérations',
                    style: theme.textTheme.bodyMedium,
                  ),
                  child: cardTransactions.isEmpty
                      ? const _EmptyTransactionsState()
                      : Column(
                          children: [
                            for (
                              int index = 0;
                              index < cardTransactions.length && index < 3;
                              index++
                            ) ...[
                              _TransactionPreviewRow(
                                transaction: cardTransactions[index],
                                onTap: () {
                                  context.go(
                                    '/transaction/${cardTransactions[index].id}',
                                  );
                                },
                              ),
                              if (index < cardTransactions.length - 1 &&
                                  index < 2)
                                const Divider(),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
          loading: () => const _LoadingState(),
          error: (Object error, StackTrace stackTrace) {
            return _ErrorState(message: error.toString());
          },
        ),
      ),
    );
  }

  Card? _resolveCard(List<Card> cards, String? selectedCardId) {
    for (final Card card in cards) {
      if (card.id == widget.cardId) {
        return card;
      }
    }

    if (selectedCardId != null) {
      for (final Card card in cards) {
        if (card.id == selectedCardId) {
          return card;
        }
      }
    }

    return null;
  }

  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    String cardId,
  ) {
    return transactions
        .where((Transaction transaction) => transaction.cardId == cardId)
        .toList(growable: false);
  }
}

String cardLabelFromId(String cardId) {
  switch (cardId) {
    case 'primary':
      return 'Compte jeunesse';
    case 'travel':
      return 'Mes cartes';
    case 'reserve':
      return 'Mes cartes';
    default:
      return 'Mes cartes';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.card, required this.onShowDetails});

  final Card card;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.72,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD100), Color(0xFFFFD100)],
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 114,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.holderName.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          card.maskedNumber.replaceFirst(
                            '**** ',
                            '5461 31XX XXXX ',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 14,
                    bottom: 12,
                    child: _MastercardBadge(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onShowDetails,
            icon: const Icon(AppIcons.eye),
            label: const Text('Détails de la carte'),
          ),
        ],
      ),
    );
  }
}

class _MastercardBadge extends StatelessWidget {
  const _MastercardBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 22,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFF79E1B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppLayout.cardRadius,
        border: Border.fromBorderSide(BorderSide(color: colorScheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              border: Border.all(color: colorScheme.outline),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ?? const Icon(AppIcons.edit, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TransactionPreviewRow extends StatelessWidget {
  const _TransactionPreviewRow({
    required this.transaction,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPositive = transaction.amount >= 0;
    final ColorScheme colorScheme = theme.colorScheme;
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${transaction.currency} ',
      decimalDigits: 2,
    );
    final DateFormat timeFormat = DateFormat('dd MMM, HH:mm');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              alignment: Alignment.center,
              child: Text(
                transaction.emoji,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${transaction.subtitle} • ${timeFormat.format(transaction.date)}',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniStatusBadge(status: transaction.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountFormat.format(transaction.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isPositive ? theme.successColor : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  const _MiniStatusBadge({required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPending = status == TransactionStatus.pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending
            ? colorScheme.primary.withValues(alpha: 0.16)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPending ? 'Pending' : 'Booked',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: AppLayout.screenPadding,
      children: [
        SizedBox(
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppLayout.cardRadius,
              border: Border.all(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppLayout.cardRadius,
              border: Border.all(color: colorScheme.outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppLayout.screenPadding,
        child: Text(
          'Unable to load card details: $message',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppLayout.screenPadding,
        child: Text(
          'Card $cardId was not found in the current dataset.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      'No recent activity is available for this card yet.',
      style: theme.textTheme.bodyMedium,
    );
  }
}
