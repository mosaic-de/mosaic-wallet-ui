import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'format.dart';
import 'goals_page.dart';
import 'panels.dart';
import 'wallet_data.dart';
import 'wallet_tiles.dart';

class WalletHome extends StatelessWidget {
  const WalletHome({super.key, required this.data});

  final WalletData data;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: MosaicSurfaceHost(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
              child: Column(
                children: [
                  Expanded(
                    child: MosaicPivot(
                      pages: [
                        MosaicPivotPage(
                          label: 'Overview',
                          child: _OverviewPage(data: data),
                        ),
                        MosaicPivotPage(
                          label: 'Activity',
                          child: _ActivityPage(data: data),
                        ),
                        MosaicPivotPage(
                          label: 'Cards',
                          child: _CardsPage(data: data),
                        ),
                        MosaicPivotPage(
                          label: 'Goals',
                          child: GoalsPage(data: data),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                  const _HomeCommandBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.data});

  final WalletData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Builder(
        builder: (context) {
          return MosaicGrid(
            children: <MosaicTileWidget>[
              BalanceTile(balance: data.balance, weeklySpend: data.weeklySpend),
              ActionTile(
                label: 'Send',
                glyph: '↗',
                onPressed: () {
                  MosaicSurfaceScope.of(context).push(
                    (_) => SendPanel(
                      balance: data.balance,
                      onSend: (recipient, cents, note) => data.recordSend(
                        recipient: recipient,
                        amountCents: cents,
                        note: note,
                      ),
                    ),
                  );
                },
              ),
              ActionTile(
                label: 'Pay',
                glyph: '◇',
                onPressed: () {
                  MosaicSurfaceScope.of(context).push(
                    (_) => PayPanel(
                      balance: data.balance,
                      transactions: data.transactions,
                      onPay: (merchant, cents) => data.recordPay(
                        merchant: merchant,
                        amountCents: cents,
                      ),
                    ),
                  );
                },
              ),
              CardsTile(cards: data.cards),
              InsightTile(weeklySpend: data.weeklySpend),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Activity (search + filter + tap-for-detail)
// ---------------------------------------------------------------------

enum _ActivityFilter { all, income, expenses }

extension on _ActivityFilter {
  String get label => switch (this) {
    _ActivityFilter.all => 'All',
    _ActivityFilter.income => 'Income',
    _ActivityFilter.expenses => 'Expenses',
  };

  bool matches(Transaction tx) => switch (this) {
    _ActivityFilter.all => true,
    _ActivityFilter.income => tx.amount > 0,
    _ActivityFilter.expenses => tx.amount < 0,
  };
}

class _ActivityPage extends StatefulWidget {
  const _ActivityPage({required this.data});

  final WalletData data;

  @override
  State<_ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<_ActivityPage> {
  String _query = '';
  _ActivityFilter _filter = _ActivityFilter.all;

  bool _matches(Transaction tx) {
    if (!_filter.matches(tx)) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return tx.label.toLowerCase().contains(q) ||
        tx.category.label.toLowerCase().contains(q) ||
        (tx.note?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: tokens.spacing.sm),
        MosaicSearchInput(
          placeholder: 'Search merchants, categories, notes',
          onChanged: (v) => setState(() => _query = v),
        ),
        SizedBox(height: tokens.spacing.sm),
        Wrap(
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.xs,
          children: [
            for (final filter in _ActivityFilter.values)
              MosaicChip(
                label: filter.label,
                selected: _filter == filter,
                onPressed: () => setState(() => _filter = filter),
              ),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        Expanded(
          child: ValueListenableBuilder<List<Transaction>>(
            valueListenable: widget.data.transactions,
            builder: (context, list, _) {
              final filtered = list.where(_matches).toList();
              if (filtered.isEmpty) {
                return MosaicEmptyState(
                  title: list.isEmpty ? 'No transactions yet' : 'No matches',
                  body: list.isEmpty
                      ? 'Once you send, pay, or get paid, the '
                          'history will show up here.'
                      : 'Try a different search term or change '
                          'the filter.',
                  glyph: list.isEmpty ? '◌' : '⌕',
                );
              }
              return MosaicList.builder(
                itemCount: filtered.length,
                builder: (context, i) {
                  final tx = filtered[i];
                  return MosaicListRow(
                    title: tx.label,
                    subtitle:
                        '${tx.category.label} · ${formatRelative(tx.when)}',
                    trailing: Text(
                      formatCents(tx.amount, withSign: true),
                      style: tokens.typography.body.copyWith(
                        color: tx.amount < 0
                            ? tokens.color.textPrimary
                            : tokens.color.success,
                      ),
                    ),
                    onPressed: () {
                      MosaicSurfaceScope.of(
                        context,
                      ).push((_) => TransactionDetailPanel(transaction: tx));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Cards (tap to push detail)
// ---------------------------------------------------------------------

class _CardsPage extends StatelessWidget {
  const _CardsPage({required this.data});

  final WalletData data;

  Color _colorFor(MosaicTokens tokens, int i) {
    final palette = <Color>[
      tokens.color.accent,
      tokens.color.warning,
      tokens.color.success,
      tokens.color.error,
    ];
    return palette[i % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return ValueListenableBuilder<List<WalletCard>>(
      valueListenable: data.cards,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const MosaicEmptyState(
            title: 'No cards',
            body: 'Add a card to start spending from this wallet.',
            glyph: '◫',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: tokens.spacing.md),
          itemBuilder: (context, i) {
            final card = list[i];
            final color = _colorFor(tokens, i);
            return MosaicPressFeedback(
              onPressed: () {
                MosaicSurfaceScope.of(context).push(
                  (_) => CardDetailPanel(
                    lastFour: card.lastFour,
                    cards: data.cards,
                    transactions: data.transactions,
                    color: color,
                    onToggleFrozen: () => data.toggleCardFrozen(card.lastFour),
                  ),
                );
              },
              semanticLabel: 'Card ${card.label}',
              child: _PaymentCard(card: card, color: color),
            );
          },
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.card, required this.color});

  final WalletCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final ink = tokens.color.textInverse;
    return AspectRatio(
      aspectRatio: 1.586,
      child: Stack(
        children: [
          MosaicSurface(
            kind: MosaicSurfaceKind.panel,
            color: color,
            padding: EdgeInsets.all(tokens.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.label,
                      style: tokens.typography.title.copyWith(color: ink),
                    ),
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '••••  ••••  ••••  ${card.lastFour}',
                  style: tokens.typography.metric.copyWith(
                    color: ink,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatCents(card.spent)} · ${formatCents(card.limit)}',
                      style: tokens.typography.caption.copyWith(
                        color: ink.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      '${(card.utilization * 100).round()}%',
                      style: tokens.typography.caption.copyWith(color: ink),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radius.pill),
                  child: SizedBox(
                    height: 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          ColoredBox(
                            color: ink.withValues(alpha: 0.2),
                            child: const SizedBox.expand(),
                          ),
                          SizedBox(
                            width: constraints.maxWidth * card.utilization,
                            child: ColoredBox(color: ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (card.frozen)
            Positioned.fill(
              child: ColoredBox(
                color: tokens.color.background.withValues(alpha: 0.55),
                child: Center(
                  child: Text(
                    'FROZEN',
                    style: tokens.typography.title.copyWith(
                      color: tokens.color.textPrimary,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Command bar
// ---------------------------------------------------------------------

class _HomeCommandBar extends StatelessWidget {
  const _HomeCommandBar();

  @override
  Widget build(BuildContext context) {
    final app = MosaicAppScope.of(context);
    return MosaicCommandBar(
      commands: [
        MosaicCommand(
          label: app.mode == MosaicMode.metro ? 'Modern' : 'Metro',
          glyph: '◐',
          onPressed: app.toggleMode,
        ),
        MosaicCommand(
          label: app.brightness == Brightness.dark ? 'Light' : 'Dark',
          glyph: '☀',
          onPressed: app.toggleBrightness,
        ),
        MosaicCommand(
          label: 'Settings',
          glyph: '⚙',
          onPressed: () {
            MosaicSurfaceScope.of(context).push((_) => const SettingsPanel());
          },
        ),
      ],
    );
  }
}
