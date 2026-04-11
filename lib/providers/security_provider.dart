import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

class SecurityState {
  const SecurityState({
    this.pinCode,
    this.isLocked = false,
    this.failedAttempts = 0,
  });

  final String? pinCode;
  final bool isLocked;
  final int failedAttempts;

  bool get hasPinCode => pinCode != null && pinCode!.isNotEmpty;

  SecurityState copyWith({
    String? pinCode,
    bool? isLocked,
    int? failedAttempts,
    bool clearPin = false,
  }) {
    return SecurityState(
      pinCode: clearPin ? null : (pinCode ?? this.pinCode),
      isLocked: isLocked ?? this.isLocked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier(this._routerRefreshNotifier) : super(const SecurityState());

  final RouterRefreshNotifier _routerRefreshNotifier;

  void setupPinCode(String pinCode) {
    state = SecurityState(pinCode: pinCode);
    _routerRefreshNotifier.notifyListeners();
  }

  bool unlockWithPinCode(String pinCode) {
    if (!state.hasPinCode) {
      return true;
    }

    if (state.pinCode == pinCode) {
      state = state.copyWith(isLocked: false, failedAttempts: 0);
      _routerRefreshNotifier.notifyListeners();
      return true;
    }

    state = state.copyWith(
      isLocked: true,
      failedAttempts: state.failedAttempts + 1,
    );
    return false;
  }

  bool verifyPinCode(String pinCode) {
    if (!state.hasPinCode) {
      return true;
    }

    if (state.pinCode == pinCode) {
      state = state.copyWith(failedAttempts: 0);
      return true;
    }

    state = state.copyWith(failedAttempts: state.failedAttempts + 1);
    return false;
  }

  void lockApp() {
    if (!state.hasPinCode) {
      return;
    }
    state = state.copyWith(isLocked: true);
    _routerRefreshNotifier.notifyListeners();
  }

  void unlockAfterBiometric() {
    if (!state.hasPinCode) {
      return;
    }
    state = state.copyWith(isLocked: false, failedAttempts: 0);
    _routerRefreshNotifier.notifyListeners();
  }

  void resetSecurity() {
    state = const SecurityState();
    _routerRefreshNotifier.notifyListeners();
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>(
  (ref) {
    final routerRefreshNotifier = ref.watch(routerRefreshNotifierProvider);
    return SecurityNotifier(routerRefreshNotifier);
  },
);
