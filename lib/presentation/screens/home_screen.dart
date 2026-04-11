import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/card_carousel_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  material.Widget build(material.BuildContext context) {
    final material.ThemeData theme = material.Theme.of(context);
    final selectedCard = ref.watch(selectedCardProvider);
    final transactions = ref.watch(selectedCardTransactionsProvider);
    final NumberFormat currency = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${selectedCard?.currency ?? AppConstants.defaultCurrency} ',
      decimalDigits: 2,
    );
    final latestTransaction = transactions.isNotEmpty
        ? transactions.first
        : null;

    final List<material.Widget> pages = <material.Widget>[
      material.ListView(
        padding: AppLayout.screenPadding,
        children: <material.Widget>[
          material.Text('Good afternoon', style: theme.textTheme.bodyMedium),
          const material.SizedBox(height: 8),
          material.Text('Wealth overview', style: theme.textTheme.displaySmall),
          const material.SizedBox(height: 24),
          const CardCarouselWidget(),
          const material.SizedBox(height: 24),
          material.Text('Shortcuts', style: theme.textTheme.titleLarge),
          const material.SizedBox(height: 12),
          material.Row(
            children: <material.Widget>[
              material.Expanded(
                child: _ShortcutTile(
                  icon: material.Icons.receipt_long_outlined,
                  label: 'Transactions',
                  onTap: () => context.go('/transactions'),
                ),
              ),
              const material.SizedBox(width: 12),
              material.Expanded(
                child: _ShortcutTile(
                  icon: material.Icons.credit_card_outlined,
                  label: 'Card details',
                  onTap: () {
                    final String cardId = selectedCard?.id ?? 'primary';
                    context.go('/card/$cardId');
                  },
                ),
              ),
            ],
          ),
          const material.SizedBox(height: 12),
          material.Row(
            children: <material.Widget>[
              material.Expanded(
                child: _ShortcutTile(
                  icon: material.Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  onTap: () => context.go('/transfer'),
                ),
              ),
              const material.SizedBox(width: 12),
              const material.Expanded(child: material.SizedBox()),
            ],
          ),
          const material.SizedBox(height: 24),
          if (selectedCard != null) ...<material.Widget>[
            _AccountCard(
              theme: theme,
              title: selectedCard.label,
              amount: currency.format(selectedCard.balance),
              iban: selectedCard.iban,
            ),
            const material.SizedBox(height: 24),
          ],
          material.Text('Highlights', style: theme.textTheme.titleLarge),
          const material.SizedBox(height: 12),
          _InsightTile(
            title: 'Portfolio balance',
            value: selectedCard == null
                ? '${AppConstants.defaultCurrency} 0.00'
                : currency.format(selectedCard.balance),
            subtitle: 'Updated today at 14:20',
          ),
          const material.SizedBox(height: 12),
          _InsightTile(
            title: latestTransaction == null
                ? 'No recent activity yet'
                : '${latestTransaction.emoji} ${latestTransaction.title}',
            value: latestTransaction == null
                ? '${AppConstants.defaultCurrency} 0.00'
                : currency.format(latestTransaction.amount),
            subtitle:
                latestTransaction?.subtitle ??
                'Transactions will appear once available',
          ),
        ],
      ),
      const _PlaceholderSection(
        title: 'Insights',
        subtitle: 'This area is reserved for future portfolio insights.',
      ),
      const _PlaceholderSection(
        title: 'Support',
        subtitle: 'Support tools and contact options will appear here.',
      ),
      _SettingsSection(
        currentThemeMode: ref.watch(themeModeProvider),
        onThemeModeChanged: (material.ThemeMode value) {
          ref.read(themeModeProvider.notifier).state = value;
        },
        onLockNow: () {
          ref.read(securityProvider.notifier).lockApp();
        },
        onLogout: () {
          ref.read(authProvider.notifier).signOut();
          context.go('/login');
        },
      ),
    ];

    return material.Scaffold(
      body: material.SafeArea(
        child: material.AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: material.KeyedSubtree(
            key: material.ValueKey<int>(_selectedIndex),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: material.NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <material.NavigationDestination>[
          material.NavigationDestination(
            icon: material.Icon(material.Icons.home_outlined),
            selectedIcon: material.Icon(material.Icons.home_rounded),
            label: 'Home',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.insights_outlined),
            selectedIcon: material.Icon(material.Icons.insights_rounded),
            label: 'Insights',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.support_agent_outlined),
            selectedIcon: material.Icon(material.Icons.support_agent_rounded),
            label: 'Support',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.person_outline_rounded),
            selectedIcon: material.Icon(material.Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderSection extends material.StatelessWidget {
  const _PlaceholderSection({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  material.Widget build(material.BuildContext context) {
    final material.ThemeData theme = material.Theme.of(context);
    final material.ColorScheme colorScheme = theme.colorScheme;

    return material.Center(
      child: material.Padding(
        padding: AppLayout.screenPadding,
        child: material.Container(
          constraints: const material.BoxConstraints(maxWidth: 520),
          padding: const material.EdgeInsets.all(24),
          decoration: material.BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppLayout.cardRadius,
            border: material.Border.fromBorderSide(
              material.BorderSide(color: colorScheme.outline),
            ),
          ),
          child: material.Column(
            mainAxisSize: material.MainAxisSize.min,
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: <material.Widget>[
              material.Text(title, style: theme.textTheme.titleLarge),
              const material.SizedBox(height: 12),
              material.Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends material.StatelessWidget {
  const _SettingsSection({
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.onLockNow,
    required this.onLogout,
  });

  final material.ThemeMode currentThemeMode;
  final material.ValueChanged<material.ThemeMode> onThemeModeChanged;
  final material.VoidCallback onLockNow;
  final material.VoidCallback onLogout;

  @override
  material.Widget build(material.BuildContext context) {
    final material.ThemeData theme = material.Theme.of(context);

    return material.ListView(
      padding: AppLayout.screenPadding,
      children: <material.Widget>[
        material.Text('Profile', style: theme.textTheme.displaySmall),
        const material.SizedBox(height: 8),
        material.Text(
          'Manage your active session and sign-in preferences.',
          style: theme.textTheme.bodyMedium,
        ),
        const material.SizedBox(height: 24),
        material.Card(
          child: material.Padding(
            padding: const material.EdgeInsets.all(20),
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: <material.Widget>[
                material.Text('Appearance', style: theme.textTheme.titleLarge),
                const material.SizedBox(height: 12),
                material.Text(
                  'Choose your preferred app theme.',
                  style: theme.textTheme.bodyMedium,
                ),
                const material.SizedBox(height: 16),
                material.SegmentedButton<material.ThemeMode>(
                  segments: const <material.ButtonSegment<material.ThemeMode>>[
                    material.ButtonSegment<material.ThemeMode>(
                      value: material.ThemeMode.light,
                      icon: material.Icon(material.Icons.light_mode_outlined),
                      label: material.Text('Light'),
                    ),
                    material.ButtonSegment<material.ThemeMode>(
                      value: material.ThemeMode.dark,
                      icon: material.Icon(material.Icons.dark_mode_outlined),
                      label: material.Text('Dark'),
                    ),
                  ],
                  selected: <material.ThemeMode>{currentThemeMode},
                  onSelectionChanged: (Set<material.ThemeMode> selection) {
                    if (selection.isEmpty) {
                      return;
                    }
                    onThemeModeChanged(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const material.SizedBox(height: 16),
        material.Card(
          child: material.Padding(
            padding: const material.EdgeInsets.all(20),
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: <material.Widget>[
                material.Text('Session', style: theme.textTheme.titleLarge),
                const material.SizedBox(height: 12),
                material.Text(
                  'Sign out to return to the secure sign-in screen.',
                  style: theme.textTheme.bodyMedium,
                ),
                const material.SizedBox(height: 20),
                material.OutlinedButton.icon(
                  onPressed: onLockNow,
                  icon: const material.Icon(
                    material.Icons.lock_outline_rounded,
                  ),
                  label: const material.Text('Lock app now'),
                ),
                const material.SizedBox(height: 12),
                material.ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const material.Icon(material.Icons.logout_rounded),
                  label: const material.Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends material.StatelessWidget {
  const _AccountCard({
    required this.theme,
    required this.title,
    required this.amount,
    required this.iban,
  });

  final material.ThemeData theme;
  final String title;
  final String amount;
  final String iban;

  @override
  material.Widget build(material.BuildContext context) {
    final material.ColorScheme colorScheme = theme.colorScheme;

    return material.Card(
      child: material.Padding(
        padding: const material.EdgeInsets.all(24),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: <material.Widget>[
            material.Text(title, style: theme.textTheme.titleMedium),
            const material.SizedBox(height: 20),
            material.Text(amount, style: theme.textTheme.displaySmall),
            const material.SizedBox(height: 8),
            material.Text(
              'Available balance',
              style: theme.textTheme.bodyMedium,
            ),
            const material.SizedBox(height: 20),
            material.Container(
              padding: const material.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: material.BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppLayout.cardRadius,
              ),
              child: material.Text(
                'IBAN $iban',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends material.StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final material.IconData icon;
  final String label;
  final material.VoidCallback onTap;

  @override
  material.Widget build(material.BuildContext context) {
    final material.ThemeData theme = material.Theme.of(context);
    final material.ColorScheme colorScheme = theme.colorScheme;

    return material.Card(
      child: material.InkWell(
        borderRadius: AppLayout.cardRadius,
        onTap: onTap,
        child: material.Padding(
          padding: const material.EdgeInsets.all(20),
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: <material.Widget>[
              material.Icon(icon, color: colorScheme.onSurface),
              const material.SizedBox(height: 20),
              material.Text(label, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightTile extends material.StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  material.Widget build(material.BuildContext context) {
    final material.ThemeData theme = material.Theme.of(context);

    return material.Card(
      child: material.Padding(
        padding: const material.EdgeInsets.all(20),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: <material.Widget>[
            material.Text(title, style: theme.textTheme.bodyMedium),
            const material.SizedBox(height: 8),
            material.Text(value, style: theme.textTheme.headlineMedium),
            const material.SizedBox(height: 8),
            material.Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
