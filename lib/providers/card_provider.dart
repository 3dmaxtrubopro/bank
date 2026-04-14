import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/card.dart';
import '../data/repositories/app_data_repository.dart';

class CardSettingsState {
  const CardSettingsState({
    this.isCardFrozen = false,
    this.is3DSecureEnabled = true,
    this.isContactlessEnabled = true,
  });

  final bool isCardFrozen;
  final bool is3DSecureEnabled;
  final bool isContactlessEnabled;

  CardSettingsState copyWith({
    bool? isCardFrozen,
    bool? is3DSecureEnabled,
    bool? isContactlessEnabled,
  }) {
    return CardSettingsState(
      isCardFrozen: isCardFrozen ?? this.isCardFrozen,
      is3DSecureEnabled: is3DSecureEnabled ?? this.is3DSecureEnabled,
      isContactlessEnabled: isContactlessEnabled ?? this.isContactlessEnabled,
    );
  }
}

class CardLimitsState {
  const CardLimitsState({
    required this.monthlyLimit,
    required this.dailyPurchaseLimit,
    required this.dailyCashLimit,
    this.monthlyUsed = 0,
    this.dailyPurchaseUsed = 0,
    this.dailyCashUsed = 0,
  });

  final double monthlyLimit;
  final double dailyPurchaseLimit;
  final double dailyCashLimit;
  final double monthlyUsed;
  final double dailyPurchaseUsed;
  final double dailyCashUsed;

  double get monthlyAvailable =>
      (monthlyLimit - monthlyUsed).clamp(0, monthlyLimit);

  double get dailyPurchaseAvailable =>
      (dailyPurchaseLimit - dailyPurchaseUsed).clamp(0, dailyPurchaseLimit);

  double get dailyCashAvailable =>
      (dailyCashLimit - dailyCashUsed).clamp(0, dailyCashLimit);

  CardLimitsState copyWith({
    double? monthlyLimit,
    double? dailyPurchaseLimit,
    double? dailyCashLimit,
    double? monthlyUsed,
    double? dailyPurchaseUsed,
    double? dailyCashUsed,
  }) {
    return CardLimitsState(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      dailyPurchaseLimit: dailyPurchaseLimit ?? this.dailyPurchaseLimit,
      dailyCashLimit: dailyCashLimit ?? this.dailyCashLimit,
      monthlyUsed: monthlyUsed ?? this.monthlyUsed,
      dailyPurchaseUsed: dailyPurchaseUsed ?? this.dailyPurchaseUsed,
      dailyCashUsed: dailyCashUsed ?? this.dailyCashUsed,
    );
  }
}

class CardSettingsNotifier
    extends StateNotifier<Map<String, CardSettingsState>> {
  CardSettingsNotifier()
    : super(const <String, CardSettingsState>{
        'primary': CardSettingsState(),
        'travel': CardSettingsState(isContactlessEnabled: false),
        'reserve': CardSettingsState(),
      });

  static const CardSettingsState _defaultSettings = CardSettingsState();

  CardSettingsState _resolve(String cardId) =>
      state[cardId] ?? _defaultSettings;

  void toggleCardFrozen(String cardId) {
    final current = _resolve(cardId);
    state = <String, CardSettingsState>{
      ...state,
      cardId: current.copyWith(isCardFrozen: !current.isCardFrozen),
    };
  }

  void set3DSecureEnabled(String cardId, bool isEnabled) {
    final current = _resolve(cardId);
    state = <String, CardSettingsState>{
      ...state,
      cardId: current.copyWith(is3DSecureEnabled: isEnabled),
    };
  }

  void setContactlessEnabled(String cardId, bool isEnabled) {
    final current = _resolve(cardId);
    state = <String, CardSettingsState>{
      ...state,
      cardId: current.copyWith(isContactlessEnabled: isEnabled),
    };
  }
}

class CardLimitsNotifier extends StateNotifier<Map<String, CardLimitsState>> {
  CardLimitsNotifier()
    : super(const <String, CardLimitsState>{
        'primary': CardLimitsState(
          monthlyLimit: 20000,
          dailyPurchaseLimit: 3000,
          dailyCashLimit: 5000,
          monthlyUsed: 1,
        ),
        'travel': CardLimitsState(
          monthlyLimit: 12000,
          dailyPurchaseLimit: 2500,
          dailyCashLimit: 1200,
          monthlyUsed: 320.45,
          dailyPurchaseUsed: 320.45,
        ),
        'reserve': CardLimitsState(
          monthlyLimit: 50000,
          dailyPurchaseLimit: 9000,
          dailyCashLimit: 5000,
          monthlyUsed: 184.9,
          dailyPurchaseUsed: 184.9,
        ),
      });

  static const CardLimitsState _defaultLimits = CardLimitsState(
    monthlyLimit: 20000,
    dailyPurchaseLimit: 3000,
    dailyCashLimit: 5000,
  );

  CardLimitsState _resolve(String cardId) => state[cardId] ?? _defaultLimits;

  bool updateLimits(
    String cardId, {
    required double monthlyLimit,
    required double dailyPurchaseLimit,
    required double dailyCashLimit,
  }) {
    final current = _resolve(cardId);
    if (monthlyLimit <= 0 || dailyPurchaseLimit <= 0 || dailyCashLimit <= 0) {
      return false;
    }
    if (monthlyLimit < current.monthlyUsed ||
        dailyPurchaseLimit < current.dailyPurchaseUsed ||
        dailyCashLimit < current.dailyCashUsed) {
      return false;
    }
    if (dailyPurchaseLimit > monthlyLimit || dailyCashLimit > monthlyLimit) {
      return false;
    }

    state = <String, CardLimitsState>{
      ...state,
      cardId: current.copyWith(
        monthlyLimit: monthlyLimit,
        dailyPurchaseLimit: dailyPurchaseLimit,
        dailyCashLimit: dailyCashLimit,
      ),
    };
    return true;
  }
}

final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return AppDataRepository.instance;
});

final cardProvider = FutureProvider<List<Card>>((ref) async {
  final repository = ref.watch(appDataRepositoryProvider);
  return repository.getCards();
});

final cardsProvider = cardProvider;

final cardSettingsProvider =
    StateNotifierProvider<CardSettingsNotifier, Map<String, CardSettingsState>>(
      (ref) => CardSettingsNotifier(),
    );

final cardSettingsByIdProvider = Provider.family<CardSettingsState, String>((
  ref,
  cardId,
) {
  return ref.watch(cardSettingsProvider)[cardId] ?? const CardSettingsState();
});

final cardLimitsProvider =
    StateNotifierProvider<CardLimitsNotifier, Map<String, CardLimitsState>>(
      (ref) => CardLimitsNotifier(),
    );

final cardLimitsByIdProvider = Provider.family<CardLimitsState, String>((
  ref,
  cardId,
) {
  return ref.watch(cardLimitsProvider)[cardId] ??
      const CardLimitsState(
        monthlyLimit: 20000,
        dailyPurchaseLimit: 3000,
        dailyCashLimit: 5000,
      );
});
