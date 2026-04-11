import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/card.dart';
import 'card_provider.dart';

final selectedCardIdProvider = StateProvider<String?>((ref) => null);

final selectedCardProvider = Provider<Card?>((ref) {
  final cards = ref.watch(cardProvider).valueOrNull;
  if (cards == null || cards.isEmpty) {
    return null;
  }

  final selectedId = ref.watch(selectedCardIdProvider);
  if (selectedId == null) {
    return cards.firstWhere(
      (card) => card.isPrimary,
      orElse: () => cards.first,
    );
  }

  for (final card in cards) {
    if (card.id == selectedId) {
      return card;
    }
  }

  return cards.firstWhere((card) => card.isPrimary, orElse: () => cards.first);
});
