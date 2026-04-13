import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../data/models/card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/theme_mode_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  material.Widget build(material.BuildContext context) {
    final cardsAsync = ref.watch(cardProvider);

    final pages = <material.Widget>[
      _HomeOverview(
        cardsAsync: cardsAsync,
        onOpenTransfer: () => context.go('/transfer'),
        onOpenCard: (cardId) => context.go('/card/$cardId'),
      ),
      const _PlaceholderSection(
        title: 'Payer',
        subtitle: 'Paiements rapides et historiques de paiements.',
      ),
      const _PlaceholderSection(
        title: 'Investir',
        subtitle: 'Vue portefeuille et performance mensuelle.',
      ),
      const _PlaceholderSection(
        title: 'Services',
        subtitle: 'Services carte, documents et support.',
      ),
      _SettingsSection(
        currentThemeMode: ref.watch(themeModeProvider),
        onThemeModeChanged: (value) {
          ref.read(themeModeProvider.notifier).state = value;
        },
        onLockNow: () => ref.read(securityProvider.notifier).lockApp(),
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
            key: material.ValueKey(_selectedIndex),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: material.NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          material.NavigationDestination(
            icon: material.Icon(material.Icons.home_outlined),
            selectedIcon: material.Icon(material.Icons.home_rounded),
            label: 'Home',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.swap_horiz_rounded),
            selectedIcon: material.Icon(material.Icons.swap_horiz_rounded),
            label: 'Payer',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.analytics_outlined),
            selectedIcon: material.Icon(material.Icons.analytics_rounded),
            label: 'Investir',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.shopping_bag_outlined),
            selectedIcon: material.Icon(material.Icons.shopping_bag_rounded),
            label: 'Services',
          ),
          material.NavigationDestination(
            icon: material.Icon(material.Icons.person_outline_rounded),
            selectedIcon: material.Icon(material.Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeOverview extends material.StatelessWidget {
  const _HomeOverview({
    required this.cardsAsync,
    required this.onOpenTransfer,
    required this.onOpenCard,
  });

  final AsyncValue<List<Card>> cardsAsync;
  final material.VoidCallback onOpenTransfer;
  final material.ValueChanged<String> onOpenCard;

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    final cs = theme.colorScheme;

    return material.Stack(
      children: [
        material.Positioned.fill(
          child: material.DecoratedBox(
            decoration: material.BoxDecoration(
              gradient: material.LinearGradient(
                colors: [
                  cs.surface,
                  cs.surface.withValues(alpha: 0.92),
                  cs.surface.withValues(alpha: 0.98),
                ],
                begin: material.Alignment.topLeft,
                end: material.Alignment.bottomRight,
              ),
            ),
          ),
        ),
        material.Positioned(
          top: -110,
          left: -70,
          child: material.Container(
            width: 250,
            height: 250,
            decoration: material.BoxDecoration(
              shape: material.BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
        material.Positioned(
          bottom: -90,
          right: -30,
          child: material.Container(
            width: 190,
            height: 190,
            decoration: material.BoxDecoration(
              shape: material.BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.06),
            ),
          ),
        ),
        material.ListView(
          padding: const material.EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _StaggerReveal(
              delay: 0,
              child: material.Row(
                children: [
                  const material.Spacer(),
                  material.Container(
                    padding: const material.EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: material.BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: material.BorderRadius.circular(20),
                    ),
                    child: material.Row(
                      children: [
                        material.Icon(
                          material.Icons.search,
                          size: 16,
                          color: cs.onSurface,
                        ),
                        const material.SizedBox(width: 8),
                        material.Text(
                          'Rechercher',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const material.SizedBox(height: 20),
            _StaggerReveal(
              delay: 80,
              child: material.Text(
                'Home',
                textAlign: material.TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
              ),
            ),
            const material.SizedBox(height: 18),
            _StaggerReveal(
              delay: 150,
              child: material.Row(
                mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionBubble(
                    icon: material.Icons.qr_code_scanner_rounded,
                    label: 'Scanner',
                    selected: true,
                    onTap: () {},
                  ),
                  _QuickActionBubble(
                    icon: material.Icons.arrow_forward_rounded,
                    label: 'Payer',
                    onTap: onOpenTransfer,
                  ),
                  _QuickActionBubble(
                    icon: material.Icons.account_balance_wallet_outlined,
                    label: 'Transférer',
                    onTap: onOpenTransfer,
                  ),
                  _QuickActionBubble(
                    icon: material.Icons.bar_chart_rounded,
                    label: 'Analyses',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const material.SizedBox(height: 20),
            _StaggerReveal(
              delay: 230,
              child: cardsAsync.when(
                data: (cards) {
                  final visibleCards = cards.take(2).toList(growable: false);
                  final formatter = NumberFormat.currency(
                    locale: AppConstants.currencyLocale,
                    symbol: '',
                    decimalDigits: 2,
                  );
                  final total = cards.fold<double>(
                    0,
                    (sum, c) => sum + c.balance,
                  );
                  return material.Column(
                    children: [
                      material.Row(
                        children: [
                          material.Text(
                            'Comptes et Dépôts',
                            style: theme.textTheme.titleMedium,
                          ),
                          const material.Spacer(),
                          material.Text(
                            'CHF ${formatter.format(total)}-',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const material.SizedBox(height: 10),
                      material.AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: material.Curves.easeOutCubic,
                        decoration: material.BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.65),
                          borderRadius: material.BorderRadius.circular(22),
                          border: material.Border.all(
                            color: cs.outline.withValues(alpha: 0.7),
                          ),
                        ),
                        child: material.Column(
                          children: [
                            for (var i = 0; i < visibleCards.length; i++) ...[
                              _AccountLine(
                                card: visibleCards[i],
                                formatter: formatter,
                                onTap: () => onOpenCard(visibleCards[i].id),
                              ),
                              if (i < visibleCards.length - 1)
                                material.Divider(
                                  color: cs.outline.withValues(alpha: 0.7),
                                  height: 1,
                                ),
                            ],
                          ],
                        ),
                      ),
                      const material.SizedBox(height: 24),
                      material.Center(
                        child: material.OutlinedButton.icon(
                          onPressed: () {},
                          icon: const material.Icon(
                            material.Icons.add_circle_outline_rounded,
                          ),
                          label: const material.Text('Ajouter un produit'),
                          style: material.OutlinedButton.styleFrom(
                            padding: const material.EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 14,
                            ),
                            shape: material.RoundedRectangleBorder(
                              borderRadius: material.BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const material.Center(
                  child: material.CircularProgressIndicator(),
                ),
                error: (error, _) => material.Text(
                  'Unable to load accounts: $error',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionBubble extends material.StatelessWidget {
  const _QuickActionBubble({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final material.IconData icon;
  final String label;
  final material.VoidCallback onTap;
  final bool selected;

  @override
  material.Widget build(material.BuildContext context) {
    final cs = material.Theme.of(context).colorScheme;
    return material.Column(
      children: [
        material.AnimatedScale(
          scale: selected ? 1 : 0.96,
          duration: const Duration(milliseconds: 220),
          curve: material.Curves.easeOutCubic,
          child: material.InkWell(
            onTap: onTap,
            borderRadius: material.BorderRadius.circular(24),
            child: material.AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: material.Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: material.BoxDecoration(
                color: selected
                    ? cs.primary
                    : cs.surfaceContainerHighest.withValues(alpha: 0.65),
                shape: material.BoxShape.circle,
              ),
              alignment: material.Alignment.center,
              child: material.Icon(
                icon,
                size: 22,
                color: selected ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
        ),
        const material.SizedBox(height: 8),
        material.Text(
          label,
          style: material.Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _AccountLine extends material.StatelessWidget {
  const _AccountLine({
    required this.card,
    required this.formatter,
    required this.onTap,
  });

  final Card card;
  final NumberFormat formatter;
  final material.VoidCallback onTap;

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    final cs = theme.colorScheme;
    return material.InkWell(
      onTap: onTap,
      borderRadius: material.BorderRadius.circular(20),
      child: material.Padding(
        padding: const material.EdgeInsets.all(16),
        child: material.Row(
          children: [
            material.Container(
              width: 30,
              height: 30,
              decoration: material.BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: material.BoxShape.circle,
              ),
              alignment: material.Alignment.center,
              child: material.Icon(
                material.Icons.account_balance_wallet_outlined,
                size: 16,
                color: cs.primary,
              ),
            ),
            const material.SizedBox(width: 12),
            material.Expanded(
              child: material.Column(
                crossAxisAlignment: material.CrossAxisAlignment.start,
                children: [
                  material.Text(card.label, style: theme.textTheme.titleMedium),
                  const material.SizedBox(height: 2),
                  material.Text(card.iban, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
            const material.SizedBox(width: 10),
            material.Text(
              'CHF ${formatter.format(card.balance)}-',
              style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
            ),
          ],
        ),
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
    final theme = material.Theme.of(context);
    return material.Center(
      child: material.Padding(
        padding: AppLayout.screenPadding,
        child: material.Container(
          constraints: const material.BoxConstraints(maxWidth: 520),
          padding: const material.EdgeInsets.all(24),
          decoration: material.BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppLayout.cardRadius,
            border: material.Border.all(color: theme.colorScheme.outline),
          ),
          child: material.Column(
            mainAxisSize: material.MainAxisSize.min,
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: [
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
    final theme = material.Theme.of(context);
    return material.ListView(
      padding: AppLayout.screenPadding,
      children: [
        material.Text('Profil', style: theme.textTheme.displaySmall),
        const material.SizedBox(height: 8),
        material.Text(
          'Gérez votre session active et vos préférences.',
          style: theme.textTheme.bodyMedium,
        ),
        const material.SizedBox(height: 24),
        material.Card(
          child: material.Padding(
            padding: const material.EdgeInsets.all(20),
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: [
                material.Text('Appearance', style: theme.textTheme.titleLarge),
                const material.SizedBox(height: 12),
                material.SegmentedButton<material.ThemeMode>(
                  segments: const [
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
                  selected: {currentThemeMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      onThemeModeChanged(selection.first);
                    }
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
              children: [
                material.Text('Session', style: theme.textTheme.titleLarge),
                const material.SizedBox(height: 12),
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

class _StaggerReveal extends material.StatelessWidget {
  const _StaggerReveal({required this.child, required this.delay});

  final material.Widget child;
  final int delay;

  @override
  material.Widget build(material.BuildContext context) {
    return material.TweenAnimationBuilder<double>(
      tween: material.Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: material.Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return material.Opacity(
          opacity: value.clamp(0, 1),
          child: material.Transform.translate(
            offset: material.Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
    );
  }
}
