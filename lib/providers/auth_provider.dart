import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/constants.dart';

enum AuthStatus { authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.isProcessing = false,
    this.biometricAttempted = false,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      isProcessing = false,
      biometricAttempted = false,
      errorMessage = null;

  const AuthState.authenticated()
    : status = AuthStatus.authenticated,
      isProcessing = false,
      biometricAttempted = true,
      errorMessage = null;

  final AuthStatus status;
  final bool isProcessing;
  final bool biometricAttempted;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    bool? isProcessing,
    bool? biometricAttempted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isProcessing: isProcessing ?? this.isProcessing,
      biometricAttempted: biometricAttempted ?? this.biometricAttempted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

enum BiometricAvailabilityStatus {
  available,
  notConfigured,
  unsupported,
  unavailable,
}

class BiometricAvailability {
  const BiometricAvailability({
    required this.status,
    required this.availableBiometrics,
    this.errorMessage,
  });

  const BiometricAvailability.unavailable()
    : status = BiometricAvailabilityStatus.unavailable,
      availableBiometrics = const <BiometricType>[],
      errorMessage = null;

  final BiometricAvailabilityStatus status;
  final List<BiometricType> availableBiometrics;
  final String? errorMessage;

  bool get isAvailable => status == BiometricAvailabilityStatus.available;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._localAuth, this._routerRefreshNotifier)
    : super(const AuthState.unauthenticated());

  final LocalAuthentication _localAuth;
  final RouterRefreshNotifier _routerRefreshNotifier;

  Future<void> signIn({
    required String username,
    required String password,
    required bool useBiometrics,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    await Future<void>.delayed(AppConstants.apiDelay);

    if (username.trim().isEmpty || password.trim().isEmpty) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Enter username and password to continue.',
      );
      return;
    }

    if (useBiometrics) {
      final biometricSuccess = await _authenticateWithBiometrics();
      if (!biometricSuccess) {
        return;
      }
    }

    _completeAuthentication();
  }

  Future<bool> authenticateOnlyBiometrics() async {
    state = state.copyWith(isProcessing: true, clearError: true);

    final biometricSuccess = await _authenticateWithBiometrics();
    if (!biometricSuccess) {
      return false;
    }

    _completeAuthentication();
    return true;
  }

  void signOut() {
    state = const AuthState.unauthenticated();
    _routerRefreshNotifier.notifyListeners();
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }
    state = state.copyWith(clearError: true);
  }

  Future<BiometricAvailability> getBiometricAvailability() async {
    if (kIsWeb) {
      return const BiometricAvailability(
        status: BiometricAvailabilityStatus.unsupported,
        availableBiometrics: <BiometricType>[],
      );
    }

    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return const BiometricAvailability(
          status: BiometricAvailabilityStatus.unsupported,
          availableBiometrics: <BiometricType>[],
        );
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (!canCheckBiometrics || availableBiometrics.isEmpty) {
        return const BiometricAvailability(
          status: BiometricAvailabilityStatus.notConfigured,
          availableBiometrics: <BiometricType>[],
        );
      }

      return BiometricAvailability(
        status: BiometricAvailabilityStatus.available,
        availableBiometrics: availableBiometrics,
      );
    } on PlatformException catch (error) {
      return BiometricAvailability(
        status: BiometricAvailabilityStatus.unavailable,
        availableBiometrics: const <BiometricType>[],
        errorMessage: _mapPlatformException(error),
      );
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    final availability = await getBiometricAvailability();

    if (!availability.isAvailable) {
      state = state.copyWith(
        isProcessing: false,
        biometricAttempted: true,
        errorMessage:
            availability.errorMessage ??
            _availabilityMessage(availability.status),
      );
      return false;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Mobile Bank',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) {
        state = state.copyWith(
          isProcessing: false,
          biometricAttempted: true,
          clearError: true,
        );
        return false;
      }

      return true;
    } on PlatformException catch (error) {
      state = state.copyWith(
        isProcessing: false,
        biometricAttempted: true,
        errorMessage: _mapPlatformException(error),
      );
      return false;
    }
  }

  void _completeAuthentication() {
    state = const AuthState.authenticated();
    _routerRefreshNotifier.notifyListeners();
  }

  String _availabilityMessage(BiometricAvailabilityStatus status) {
    switch (status) {
      case BiometricAvailabilityStatus.available:
        return 'Biometrics are available.';
      case BiometricAvailabilityStatus.notConfigured:
        return 'Biometrics are not set up on this device.';
      case BiometricAvailabilityStatus.unsupported:
        return 'This device does not support biometric authentication.';
      case BiometricAvailabilityStatus.unavailable:
        return 'Biometric authentication is currently unavailable.';
    }
  }

  String _mapPlatformException(PlatformException error) {
    switch (error.code) {
      case 'NotAvailable':
        return 'Biometric authentication is currently unavailable.';
      case 'NotEnrolled':
        return 'Biometrics are not set up on this device.';
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is temporarily locked. Use your password and try again later.';
      default:
        return 'Biometric authentication failed. Please try again.';
    }
  }
}

class RouterRefreshNotifier extends ChangeNotifier {
  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final localAuth = ref.watch(localAuthProvider);
  final routerRefreshNotifier = ref.watch(routerRefreshNotifierProvider);
  return AuthNotifier(localAuth, routerRefreshNotifier);
});

final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>((
  ref,
) {
  return ref.watch(authProvider.notifier).getBiometricAvailability();
});
