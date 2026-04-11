import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants.dart';
import '../../data/models/card.dart';
import '../../providers/card_provider.dart';
import '../../providers/selected_card_provider.dart';
import '../../routes.dart';

class CardCarouselWidget extends ConsumerWidget {
  const CardCarouselWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardProvider);

    return cards.when(
      data: (items) => _CardCarouselContent(cards: items),
      loading: () => const _CardCarouselSkeleton(),
      error: (error, stackTrace) => _CardCarouselError(message: error.toString()),
    );
  }
}

class _CardCarouselContent extends ConsumerWidget {
  const _CardCarouselContent({required this.cards});

  final List<Card> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCard = ref.watch(selectedCardProvider) ?? cards.first;

    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final card = cards[index];
          final isSelected = card.id == selectedCard.id;

          return SizedBox(
            width: 308,
            child: _CardTile(
              card: card,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedCardIdProvider.notifier).state = card.id;
              },
              onDetailsTap: () {
                ref.read(selectedCardIdProvider.notifier).state = card.id;
                ref.read(routerProvider).go('/card/${card.id}');
              },
            ),
          );
        },
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
    required this.onDetailsTap,
  });

  final Card card;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final formatter = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${card.currency} ',
      decimalDigits: 2,
    );
    final borderColor = isSelected ? AppColors.alert : AppColors.line;
    final borderWidth = isSelected ? 2.0 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppLayout.cardRadius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: AppLayout.cardRadius,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (card.isPrimary) const SizedBox(width: 12),
                    if (card.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.alert),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.alert,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Available balance',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.steel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatter.format(card.balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMaskedNumber(card.maskedNumber),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            strutStyle: const StrutStyle(
                              forceStrutHeight: true,
                              height: 1.1,
                            ),
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.holderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.steel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: onDetailsTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alert,
                          side: const BorderSide(color: AppColors.alert),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardCarouselSkeleton extends StatelessWidget {
  const _CardCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: colorScheme.outlineVariant,
            highlightColor: colorScheme.surfaceContainerHighest,
            child: Container(
              width: 308,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: AppLayout.cardRadius,
                border: Border.all(color: AppColors.line),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardCarouselError extends StatelessWidget {
  const _CardCarouselError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: AppLayout.cardRadius,
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        'Unable to load cards: $message',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

String _formatMaskedNumber(String maskedNumber) {
  final digits = maskedNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return maskedNumber.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  final visibleDigits = digits.length >= 4
      ? digits.substring(digits.length - 4)
      : digits.padLeft(4, '0');
  final groups = <String>['****', '****', '****', visibleDigits];

  final originalMaskCount = RegExp(r'\*').allMatches(maskedNumber).length;
  final hiddenGroupCount = math.max(1, math.min(3, (originalMaskCount / 4).round()));

  return groups.take(hiddenGroupCount + 1).join(' ');
}
