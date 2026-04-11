import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/card.dart';
import '../data/repositories/app_data_repository.dart';

final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return AppDataRepository.instance;
});

final cardProvider = FutureProvider<List<Card>>((ref) async {
  final repository = ref.watch(appDataRepositoryProvider);
  return repository.getCards();
});

final cardsProvider = cardProvider;
