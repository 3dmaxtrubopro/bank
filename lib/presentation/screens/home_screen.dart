import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../data/models/card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/selected_card_provider.dart';
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
    final theme = material.Theme.of(context);
    final cardsAsync = ref.watch(cardProvider);
    Future<bool> updateCardDetails({
      required String cardId,
      required String label,
      required String holderName,
      required String iban,
      required double balance,
    }) async {
      final repository = ref.read(appDataRepositoryProvider);
      final saved = await repository.updateCardDetails(
        cardId: cardId,
        label: label,
        holderName: holderName,
        iban: iban,
        balance: balance,
      );
      if (saved) {
        ref.invalidate(cardProvider);
      }
      return saved;
    }

    final pages = <material.Widget>[
      _HomeOverview(
        cardsAsync: cardsAsync,
        onOpenTransfer: () => context.go('/transfer'),
        onOpenCardTransactions: (cardId) {
          ref.read(selectedCardIdProvider.notifier).state = cardId;
          context.go('/transactions');
        },
        onUpdateCardDetails:
            ({
              required cardId,
              required label,
              required holderName,
              required iban,
              required balance,
            }) => updateCardDetails(
              cardId: cardId,
              label: label,
              holderName: holderName,
              iban: iban,
              balance: balance,
            ),
      ),
      const _PlaceholderSection(
        title: 'Payer',
        subtitle: 'Paiements rapides et historiques de paiements.',
      ),
      const _PlaceholderSection(
        title: 'Investir',
        subtitle: 'Vue portefeuille et performance mensuelle.',
      ),
      _ShopSection(
        cardsAsync: cardsAsync,
        onOpenCard: (cardId) {
          ref.read(selectedCardIdProvider.notifier).state = cardId;
          context.go('/card/$cardId');
        },
      ),
      _ServicesHubSection(
        cardsAsync: cardsAsync,
        onOpenCard: (cardId) {
          ref.read(selectedCardIdProvider.notifier).state = cardId;
          context.go('/card/$cardId');
        },
        onUpdateCardDetails:
            ({
              required cardId,
              required label,
              required holderName,
              required iban,
              required balance,
            }) => updateCardDetails(
              cardId: cardId,
              label: label,
              holderName: holderName,
              iban: iban,
              balance: balance,
            ),
        onOpenProfileSettings: () {
          _showProfileSettingsSheet(context);
        },
        onOpenPreviewAction: (label) {
          material.ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              material.SnackBar(
                content: material.Text('$label est disponible en preview.'),
              ),
            );
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
            key: material.ValueKey(_selectedIndex),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: material.NavigationBarTheme(
        data: material.NavigationBarThemeData(
          height: 72,
          backgroundColor: const material.Color(0xFF022A33),
          indicatorColor: const material.Color(0x1ACDE7EC),
          indicatorShape: const material.StadiumBorder(),
          labelTextStyle: material.WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(material.WidgetState.selected);
            return theme.textTheme.labelSmall?.copyWith(
                  fontWeight:
                      selected
                          ? material.FontWeight.w700
                          : material.FontWeight.w500,
                  color: selected
                      ? const material.Color(0xFFE6F2F5)
                      : const material.Color(0xFF91B4BB),
                ) ??
                const material.TextStyle(fontSize: 11);
          }),
          iconTheme: material.WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(material.WidgetState.selected);
            return material.IconThemeData(
              color: selected
                  ? const material.Color(0xFFE6F2F5)
                  : const material.Color(0xFF91B4BB),
            );
          }),
        ),
        child: material.NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          labelBehavior: material.NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            material.NavigationDestination(
              icon: material.Icon(AppIcons.homeOutlined, size: 20),
              selectedIcon: material.Icon(AppIcons.homeFilled, size: 20),
              label: 'Home',
            ),
            material.NavigationDestination(
              icon: material.Icon(AppIcons.payOutlined, size: 20),
              selectedIcon: material.Icon(AppIcons.payFilled, size: 20),
              label: 'Paiements',
            ),
            material.NavigationDestination(
              icon: material.Icon(AppIcons.insightsOutlined, size: 20),
              selectedIcon: material.Icon(AppIcons.insightsFilled, size: 20),
              label: 'Investir',
            ),
            material.NavigationDestination(
              icon: material.Icon(AppIcons.servicesOutlined, size: 20),
              selectedIcon: material.Icon(AppIcons.servicesFilled, size: 20),
              label: 'Offer',
            ),
            material.NavigationDestination(
              icon: material.Icon(AppIcons.profileOutlined, size: 20),
              selectedIcon: material.Icon(AppIcons.profileFilled, size: 20),
              label: 'Services',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileSettingsSheet(material.BuildContext context) async {
    await material.showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return material.SizedBox(
          height: material.MediaQuery.of(sheetContext).size.height * 0.8,
          child: _SettingsSection(
            currentThemeMode: ref.read(themeModeProvider),
            onThemeModeChanged: (value) {
              ref.read(themeModeProvider.notifier).state = value;
            },
            onLockNow: () => ref.read(securityProvider.notifier).lockApp(),
            onLogout: () {
              ref.read(authProvider.notifier).signOut();
              if (sheetContext.mounted) {
                material.Navigator.of(sheetContext).pop();
              }
              context.go('/login');
            },
          ),
        );
      },
    );
  }
}

class _HomeOverview extends material.StatelessWidget {
  const _HomeOverview({
    required this.cardsAsync,
    required this.onOpenTransfer,
    required this.onOpenCardTransactions,
    required this.onUpdateCardDetails,
  });

  final AsyncValue<List<Card>> cardsAsync;
  final material.VoidCallback onOpenTransfer;
  final material.ValueChanged<String> onOpenCardTransactions;
  final Future<bool> Function({
    required String cardId,
    required String label,
    required String holderName,
    required String iban,
    required double balance,
  })
  onUpdateCardDetails;

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
          padding: const material.EdgeInsets.fromLTRB(18, 8, 18, 20),
          children: [
            _StaggerReveal(
              delay: 0,
              child: material.Row(
                children: [
                  const material.Spacer(),
                  material.Container(
                    padding: const material.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: material.BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: material.BorderRadius.circular(18),
                    ),
                    child: material.Row(
                      children: [
                        material.Icon(
                          AppIcons.search,
                          size: 14,
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
            const material.SizedBox(height: 16),
            _StaggerReveal(
              delay: 80,
              child: material.Text(
                'Home',
                textAlign: material.TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
              ),
            ),
            const material.SizedBox(height: 14),
            _StaggerReveal(
              delay: 150,
              child: material.Row(
                mainAxisAlignment: material.MainAxisAlignment.spaceAround,
                children: [
                  _QuickActionBubble(
                    icon: AppIcons.scanner,
                    label: 'Scanner',
                    selected: true,
                    onTap: () {},
                  ),
                  _QuickActionBubble(
                    icon: AppIcons.transfer,
                    label: 'Payer',
                    onTap: onOpenTransfer,
                  ),
                  _QuickActionBubble(
                    icon: AppIcons.wallet,
                    label: 'Transférer',
                    onTap: onOpenTransfer,
                  ),
                  _QuickActionBubble(
                    icon: AppIcons.analytics,
                    label: 'Analyses',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const material.SizedBox(height: 16),
            _StaggerReveal(
              delay: 230,
              child: cardsAsync.when(
                data: (cards) {
                  final visibleCards = cards.take(3).toList(growable: false);
                  final formatter = NumberFormat.currency(
                    locale: AppConstants.currencyLocale,
                    symbol: '',
                    decimalDigits: 2,
                  );
                  final total = visibleCards.fold<double>(
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
                          borderRadius: material.BorderRadius.circular(18),
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
                                onTap: () =>
                                    onOpenCardTransactions(visibleCards[i].id),
                                onLongPress: () {
                                  _showEditIbanSheet(
                                    context: context,
                                    card: visibleCards[i],
                                  );
                                },
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
                          icon: const material.Icon(AppIcons.add),
                          label: const material.Text('Ajouter un produit'),
                          style: material.OutlinedButton.styleFrom(
                            padding: const material.EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            shape: material.RoundedRectangleBorder(
                              borderRadius: material.BorderRadius.circular(999),
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

  Future<void> _showEditIbanSheet({
    required material.BuildContext context,
    required Card card,
  }) async {
    final labelController = material.TextEditingController(text: card.label);
    final holderController = material.TextEditingController(
      text: card.holderName,
    );
    final ibanController = material.TextEditingController(text: card.iban);
    final balanceController = material.TextEditingController(
      text: card.balance.toStringAsFixed(2),
    );
    final messenger = material.ScaffoldMessenger.of(context);
    final saved = await material.showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return material.AlertDialog(
          title: const material.Text('Modifier le compte'),
          content: material.Column(
            mainAxisSize: material.MainAxisSize.min,
            children: [
              material.TextFormField(
                controller: labelController,
                decoration: const material.InputDecoration(
                  labelText: 'Nom du compte',
                ),
              ),
              const material.SizedBox(height: 10),
              material.TextFormField(
                controller: holderController,
                decoration: const material.InputDecoration(
                  labelText: 'Titulaire',
                ),
              ),
              const material.SizedBox(height: 10),
              material.TextFormField(
                controller: ibanController,
                decoration: const material.InputDecoration(
                  labelText: 'IBAN',
                  hintText: 'CH00 0000 0000 0000 0000 0',
                ),
                textInputAction: material.TextInputAction.done,
              ),
              const material.SizedBox(height: 10),
              material.TextFormField(
                controller: balanceController,
                keyboardType: const material.TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: const material.InputDecoration(
                  labelText: 'Solde (CHF)',
                  hintText: '128450.90',
                ),
              ),
            ],
          ),
          actions: [
            material.TextButton(
              onPressed: () => material.Navigator.of(dialogContext).pop(false),
              child: const material.Text('Annuler'),
            ),
            material.FilledButton(
              onPressed: () async {
                final parsedBalance = double.tryParse(
                  balanceController.text.replaceAll(',', '.').trim(),
                );
                if (parsedBalance == null) {
                  if (dialogContext.mounted) {
                    material.ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const material.SnackBar(
                        content: material.Text('Solde invalide.'),
                      ),
                    );
                  }
                  return;
                }
                final ok = await onUpdateCardDetails(
                  cardId: card.id,
                  label: labelController.text,
                  holderName: holderController.text,
                  iban: ibanController.text,
                  balance: parsedBalance,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                material.Navigator.of(dialogContext).pop(ok);
              },
              child: const material.Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    labelController.dispose();
    holderController.dispose();
    ibanController.dispose();
    balanceController.dispose();

    if (!context.mounted || saved == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        material.SnackBar(
          content: material.Text(
            saved
                ? 'Données du compte mises à jour.'
                : 'Impossible de mettre à jour les données.',
          ),
        ),
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
              height: 46,
              decoration: material.BoxDecoration(
                color: selected
                    ? cs.primary
                    : cs.surfaceContainerHighest.withValues(alpha: 0.65),
                shape: material.BoxShape.circle,
              ),
              alignment: material.Alignment.center,
              child: material.Icon(
                icon,
                size: 20,
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
    required this.onLongPress,
  });

  final Card card;
  final NumberFormat formatter;
  final material.VoidCallback onTap;
  final material.VoidCallback onLongPress;

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    final cs = theme.colorScheme;
    return material.InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: material.BorderRadius.circular(20),
      child: material.Padding(
        padding: const material.EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: material.Row(
          children: [
            material.Container(
              width: 28,
              height: 28,
              decoration: material.BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: material.BoxShape.circle,
              ),
              alignment: material.Alignment.center,
              child: material.Icon(
                AppIcons.wallet,
                size: 14,
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

class _ShopSection extends material.StatelessWidget {
  const _ShopSection({required this.cardsAsync, required this.onOpenCard});

  final AsyncValue<List<Card>> cardsAsync;
  final material.ValueChanged<String> onOpenCard;

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    final cs = theme.colorScheme;
    final amountFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: 'CHF ',
      decimalDigits: 2,
    );

    return material.ListView(
      padding: AppLayout.screenPadding,
      children: [
        material.Text('Mes cartes', style: theme.textTheme.displaySmall),
        const material.SizedBox(height: 10),
        material.Text(
          'Vos cartes et paramètres de paiement.',
          style: theme.textTheme.bodyMedium,
        ),
        const material.SizedBox(height: 18),
        cardsAsync.when(
          data: (cards) {
            return material.DecoratedBox(
              decoration: material.BoxDecoration(
                color: cs.surface,
                borderRadius: AppLayout.cardRadius,
                border: material.Border.all(color: cs.outline),
              ),
              child: material.Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    material.ListTile(
                      onTap: () => onOpenCard(cards[i].id),
                      contentPadding: const material.EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      leading: material.Container(
                        width: 34,
                        height: 22,
                        decoration: material.BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.22),
                          borderRadius: material.BorderRadius.circular(4),
                        ),
                      ),
                      title: material.Text(
                        '${cards[i].label} · ${cards[i].maskedNumber}',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: material.Text(
                        amountFormat.format(cards[i].balance),
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: const material.Icon(AppIcons.chevronRight),
                    ),
                    if (i < cards.length - 1)
                      material.Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.outline.withValues(alpha: 0.6),
                      ),
                  ],
                ],
              ),
            );
          },
          loading: () => const material.Center(
            child: material.CircularProgressIndicator(),
          ),
          error: (error, _) => material.Text(
            'Unable to load cards: $error',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ServicesHubSection extends material.StatelessWidget {
  const _ServicesHubSection({
    required this.cardsAsync,
    required this.onOpenCard,
    required this.onUpdateCardDetails,
    required this.onOpenProfileSettings,
    required this.onOpenPreviewAction,
    required this.onLogout,
  });

  final AsyncValue<List<Card>> cardsAsync;
  final material.ValueChanged<String> onOpenCard;
  final Future<bool> Function({
    required String cardId,
    required String label,
    required String holderName,
    required String iban,
    required double balance,
  })
  onUpdateCardDetails;
  final material.VoidCallback onOpenProfileSettings;
  final material.ValueChanged<String> onOpenPreviewAction;
  final material.VoidCallback onLogout;

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);
    const backgroundA = material.Color(0xFF012F39);
    const backgroundB = material.Color(0xFF022630);
    const backgroundC = material.Color(0xFF01242D);
    const panelColor = material.Color(0xFF022831);
    const iconColor = material.Color(0xFFBDD2D8);
    const textColor = material.Color(0xFFE6F2F5);

    return material.Stack(
      children: [
        const material.Positioned.fill(
          child: material.DecoratedBox(
            decoration: material.BoxDecoration(
              gradient: material.LinearGradient(
                colors: [backgroundA, backgroundB, backgroundC],
                begin: material.Alignment.topCenter,
                end: material.Alignment.bottomRight,
              ),
            ),
          ),
        ),
        material.Positioned(
          top: -72,
          left: -58,
          child: material.Container(
            width: 238,
            height: 238,
            decoration: const material.BoxDecoration(
              shape: material.BoxShape.circle,
              color: material.Color(0x1F0797A5),
            ),
          ),
        ),
        material.Positioned(
          top: 120,
          right: -110,
          child: material.Container(
            width: 260,
            height: 260,
            decoration: const material.BoxDecoration(
              shape: material.BoxShape.circle,
              color: material.Color(0x140AA8B7),
            ),
          ),
        ),
        material.Positioned(
          bottom: -126,
          right: -62,
          child: material.Container(
            width: 296,
            height: 296,
            decoration: const material.BoxDecoration(
              shape: material.BoxShape.circle,
              color: material.Color(0x1807A9B8),
            ),
          ),
        ),
        material.ListView(
          padding: const material.EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            material.Align(
              alignment: material.Alignment.centerRight,
              child: material.Container(
                padding: const material.EdgeInsets.symmetric(
                  horizontal: 13.5,
                  vertical: 7.5,
                ),
                decoration: material.BoxDecoration(
                  color: const material.Color(0x2A00161D),
                  borderRadius: material.BorderRadius.circular(20),
                  border: material.Border.all(
                    color: const material.Color(0x400E4A56),
                  ),
                ),
                child: material.Row(
                  mainAxisSize: material.MainAxisSize.min,
                  children: [
                    const material.Icon(
                      material.Icons.search_rounded,
                      size: 16,
                      color: material.Color(0xFFC7DBE0),
                    ),
                    const material.SizedBox(width: 6),
                    material.Text(
                      'Rechercher',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const material.Color(0xFFBDD3D8),
                        fontWeight: material.FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const material.SizedBox(height: 24),
            material.Center(
              child: material.Text(
                'Services',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: textColor,
                  fontWeight: material.FontWeight.w600,
                ),
              ),
            ),
            const material.SizedBox(height: 20),
            material.Container(
              decoration: material.BoxDecoration(
                color: panelColor.withValues(alpha: 0.97),
                borderRadius: material.BorderRadius.circular(26),
                border: material.Border.all(
                  color: const material.Color(0x330F5662),
                ),
              ),
              child: material.Column(
                children: [
                  _ServiceTile(
                    icon: AppIcons.card,
                    iconColor: iconColor,
                    textColor: textColor,
                    label: 'Cartes',
                    onTap: () => _openCardsSheet(context),
                  ),
                  _ServiceTile(
                    icon: material.Icons.notifications_none_rounded,
                    iconColor: iconColor,
                    textColor: textColor,
                    label: 'Notifications',
                    showDot: true,
                    onTap: () => onOpenPreviewAction('Notifications'),
                  ),
                  _ServiceTile(
                    icon: material.Icons.receipt_long_outlined,
                    iconColor: iconColor,
                    textColor: textColor,
                    label: 'Documents',
                    onTap: () => onOpenPreviewAction('Documents'),
                  ),
                  _ServiceTile(
                    icon: material.Icons.manage_accounts_outlined,
                    iconColor: iconColor,
                    textColor: textColor,
                    label: 'Profil et paramètres',
                    onTap: onOpenProfileSettings,
                  ),
                  _ServiceTile(
                    icon: material.Icons.help_outline_rounded,
                    iconColor: iconColor,
                    textColor: textColor,
                    label: 'Contact et assistance',
                    onTap: () => onOpenPreviewAction('Contact et assistance'),
                  ),
                ],
              ),
            ),
            const material.SizedBox(height: 18),
            material.Material(
              color: panelColor.withValues(alpha: 0.97),
              borderRadius: material.BorderRadius.circular(18),
              child: material.InkWell(
                onTap: onLogout,
                borderRadius: material.BorderRadius.circular(18),
                child: material.Padding(
                  padding: const material.EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: material.Row(
                    children: [
                      const material.Icon(
                        AppIcons.logout,
                        color: iconColor,
                        size: 21,
                      ),
                      const material.SizedBox(width: 14),
                      material.Text(
                        'Logout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: material.FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openCardsSheet(material.BuildContext context) async {
    final messenger = material.ScaffoldMessenger.of(context);
    await material.showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return cardsAsync.when(
          data: (cards) {
            return material.SafeArea(
              child: material.ListView(
                shrinkWrap: true,
                children: [
                  for (final card in cards)
                    material.ListTile(
                      leading: const material.Icon(AppIcons.card),
                      title: material.Text(card.label),
                      subtitle: material.Text(card.maskedNumber),
                      trailing: const material.Icon(AppIcons.chevronRight),
                      onTap: () {
                        material.Navigator.of(sheetContext).pop();
                        onOpenCard(card.id);
                      },
                      onLongPress: () async {
                        material.Navigator.of(sheetContext).pop();
                        await _showEditCardSheet(
                          context: context,
                          card: card,
                          messenger: messenger,
                        );
                      },
                    ),
                ],
              ),
            );
          },
          loading: () => const material.Padding(
            padding: material.EdgeInsets.all(24),
            child: material.Center(child: material.CircularProgressIndicator()),
          ),
          error: (error, _) => material.Padding(
            padding: const material.EdgeInsets.all(24),
            child: material.Text('Unable to load cards: $error'),
          ),
        );
      },
    );
  }

  Future<void> _showEditCardSheet({
    required material.BuildContext context,
    required Card card,
    required material.ScaffoldMessengerState messenger,
  }) async {
    final labelController = material.TextEditingController(text: card.label);
    final holderController = material.TextEditingController(
      text: card.holderName,
    );
    final ibanController = material.TextEditingController(text: card.iban);
    final balanceController = material.TextEditingController(
      text: card.balance.toStringAsFixed(2),
    );
    final saved = await material.showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return material.AlertDialog(
          title: const material.Text('Modifier le compte'),
          content: material.Column(
            mainAxisSize: material.MainAxisSize.min,
            children: [
              material.TextFormField(
                controller: labelController,
                decoration: const material.InputDecoration(
                  labelText: 'Nom du compte',
                ),
              ),
              const material.SizedBox(height: 10),
              material.TextFormField(
                controller: holderController,
                decoration: const material.InputDecoration(
                  labelText: 'Titulaire',
                ),
              ),
              const material.SizedBox(height: 10),
              material.TextFormField(
                controller: ibanController,
                decoration: const material.InputDecoration(
                  labelText: 'IBAN',
                  hintText: 'CH00 0000 0000 0000 0000 0',
                ),
                textInputAction: material.TextInputAction.done,
              ),
              const material.SizedBox(height: 10),
              material.TextFormField(
                controller: balanceController,
                keyboardType: const material.TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: const material.InputDecoration(
                  labelText: 'Solde (CHF)',
                  hintText: '128450.90',
                ),
              ),
            ],
          ),
          actions: [
            material.TextButton(
              onPressed: () => material.Navigator.of(dialogContext).pop(false),
              child: const material.Text('Annuler'),
            ),
            material.FilledButton(
              onPressed: () async {
                final parsedBalance = double.tryParse(
                  balanceController.text.replaceAll(',', '.').trim(),
                );
                if (parsedBalance == null) {
                  if (dialogContext.mounted) {
                    material.ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const material.SnackBar(
                        content: material.Text('Solde invalide.'),
                      ),
                    );
                  }
                  return;
                }
                final ok = await onUpdateCardDetails(
                  cardId: card.id,
                  label: labelController.text,
                  holderName: holderController.text,
                  iban: ibanController.text,
                  balance: parsedBalance,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                material.Navigator.of(dialogContext).pop(ok);
              },
              child: const material.Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    labelController.dispose();
    holderController.dispose();
    ibanController.dispose();
    balanceController.dispose();
    if (!context.mounted || saved == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        material.SnackBar(
          content: material.Text(
            saved
                ? 'Données du compte mises à jour.'
                : 'Impossible de mettre à jour les données.',
          ),
        ),
      );
  }
}

class _ServiceTile extends material.StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final material.IconData icon;
  final material.Color iconColor;
  final material.Color textColor;
  final String label;
  final material.VoidCallback onTap;
  final bool showDot;

  @override
  material.Widget build(material.BuildContext context) {
    final theme = material.Theme.of(context);

    return material.InkWell(
      onTap: onTap,
      borderRadius: material.BorderRadius.circular(16),
      child: material.Padding(
        padding: const material.EdgeInsets.symmetric(
          horizontal: 18.5,
          vertical: 13,
        ),
        child: material.Row(
          children: [
            material.Stack(
              clipBehavior: material.Clip.none,
              children: [
                material.Icon(icon, size: 19, color: iconColor),
                if (showDot)
                  const material.Positioned(
                    top: 0.5,
                    right: -4.5,
                    child: material.CircleAvatar(
                      radius: 2.6,
                      backgroundColor: material.Color(0xFFFF6D7A),
                    ),
                  ),
              ],
            ),
            const material.SizedBox(width: 12),
            material.Expanded(
              child: material.Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: material.FontWeight.w500,
                ),
              ),
            ),
          ],
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
                      icon: material.Icon(AppIcons.lightMode),
                      label: material.Text('Light'),
                    ),
                    material.ButtonSegment<material.ThemeMode>(
                      value: material.ThemeMode.dark,
                      icon: material.Icon(AppIcons.darkMode),
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
                  icon: const material.Icon(AppIcons.lock),
                  label: const material.Text('Lock app now'),
                ),
                const material.SizedBox(height: 12),
                material.ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const material.Icon(AppIcons.logout),
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
