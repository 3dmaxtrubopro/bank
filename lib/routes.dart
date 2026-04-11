import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/card_detail_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/setup_pin_screen.dart';
import 'presentation/screens/transaction_detail_screen.dart';
import 'presentation/screens/transactions_screen.dart';
import 'presentation/screens/transfer_screen.dart';
import 'presentation/screens/unlock_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/security_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final securityState = ref.read(securityProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSetupPinRoute = state.matchedLocation == '/setup-pin';
      final isUnlockRoute = state.matchedLocation == '/unlock';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (!isAuthenticated) {
        return null;
      }

      if (!securityState.hasPinCode && !isSetupPinRoute) {
        return '/setup-pin';
      }

      if (securityState.hasPinCode &&
          securityState.isLocked &&
          !isUnlockRoute) {
        return '/unlock';
      }

      if (isLoginRoute) {
        if (!securityState.hasPinCode) {
          return '/setup-pin';
        }
        if (securityState.isLocked) {
          return '/unlock';
        }
        return '/';
      }

      if (isSetupPinRoute && securityState.hasPinCode) {
        return '/';
      }

      if (isUnlockRoute && !securityState.isLocked) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/setup-pin',
        builder: (context, state) => const SetupPinScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: 'transfer',
            builder: (context, state) => TransferScreen(
              initialRecipient: state.uri.queryParameters['recipient'],
              initialIban: state.uri.queryParameters['iban'],
              initialNote: state.uri.queryParameters['note'],
              initialAmount: state.uri.queryParameters['amount'],
            ),
          ),
          GoRoute(
            path: 'transaction/:transactionId',
            builder: (context, state) {
              final transactionId = state.pathParameters['transactionId'] ?? '';
              return TransactionDetailScreen(transactionId: transactionId);
            },
          ),
          GoRoute(
            path: 'card/:cardId',
            builder: (context, state) {
              final cardId = state.pathParameters['cardId'] ?? 'primary';
              return CardDetailScreen(cardId: cardId);
            },
          ),
        ],
      ),
    ],
  );
});
