import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'format.dart';
import 'wallet_data.dart';

class BalanceTile extends StatelessWidget implements MosaicTileWidget {
  const BalanceTile({
    super.key,
    required this.balance,
    required this.weeklySpend,
  });

  @override
  MosaicTileSize get size => MosaicTileSize.wide;

  final ValueListenable<int> balance;
  final ValueListenable<int> weeklySpend;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicLiveTile<int>(
      size: MosaicTileSize.wide,
      source: MosaicLiveSource<int>.fromListenable(balance),
      padding: EdgeInsets.all(tokens.spacing.md),
      semanticLabel: 'Wallet balance',
      tileBuilder: (context, value, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Balance',
                style: tokens.typography.tileSubtitle.copyWith(
                  color: tokens.color.textSecondary,
                ),
              ),
              SizedBox(height: tokens.spacing.xs),
              Text(
                formatCents(value),
                style: tokens.typography.headline.copyWith(
                  color: tokens.color.textPrimary,
                ),
              ),
              SizedBox(height: tokens.spacing.xs),
              ValueListenableBuilder<int>(
                valueListenable: weeklySpend,
                builder: (context, spend, _) {
                  return Text(
                    'This week  ${formatCents(spend)}',
                    style: tokens.typography.caption.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ActionTile extends StatelessWidget implements MosaicTileWidget {
  const ActionTile({
    super.key,
    required this.label,
    required this.glyph,
    required this.onPressed,
  });

  @override
  MosaicTileSize get size => MosaicTileSize.medium;

  final String label;
  final String glyph;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicTile(
      size: MosaicTileSize.medium,
      onPressed: onPressed,
      kind: MosaicSurfaceKind.muted,
      padding: EdgeInsets.all(tokens.spacing.md),
      semanticLabel: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            glyph,
            style: tokens.typography.metric.copyWith(
              color: tokens.color.accent,
            ),
          ),
          Text(
            label,
            style: tokens.typography.tileTitle.copyWith(
              color: tokens.color.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsTile extends StatelessWidget implements MosaicTileWidget {
  const TransactionsTile({super.key, required this.transactions});

  @override
  MosaicTileSize get size => MosaicTileSize.large;

  final ValueListenable<List<Transaction>> transactions;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicLiveTile<List<Transaction>>(
      size: MosaicTileSize.large,
      source: MosaicLiveSource<List<Transaction>>.fromListenable(
        transactions,
        isEmpty: (xs) => xs.isEmpty,
      ),
      padding: EdgeInsets.all(tokens.spacing.md),
      semanticLabel: 'Recent transactions',
      tileBuilder: (context, value, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: tokens.typography.tileSubtitle.copyWith(
                    color: tokens.color.textSecondary,
                  ),
                ),
                if (state is DataReady<List<Transaction>> && state.isUpdating)
                  Text(
                    'updating',
                    style: tokens.typography.caption.copyWith(
                      color: tokens.color.accent,
                    ),
                  ),
              ],
            ),
            SizedBox(height: tokens.spacing.sm),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: value.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: tokens.spacing.sm),
                itemBuilder: (context, i) {
                  final tx = value[i];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.label,
                              style: tokens.typography.body.copyWith(
                                color: tokens.color.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatRelative(tx.when),
                              style: tokens.typography.caption.copyWith(
                                color: tokens.color.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCents(tx.amount, withSign: true),
                        style: tokens.typography.body.copyWith(
                          color: tx.amount < 0
                              ? tokens.color.textPrimary
                              : tokens.color.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class CardsTile extends StatelessWidget implements MosaicTileWidget {
  const CardsTile({super.key, required this.cards});

  @override
  MosaicTileSize get size => MosaicTileSize.medium;

  final ValueListenable<List<WalletCard>> cards;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicLiveTile<List<WalletCard>>(
      size: MosaicTileSize.medium,
      source: MosaicLiveSource<List<WalletCard>>.fromListenable(
        cards,
        isEmpty: (xs) => xs.isEmpty,
      ),
      padding: EdgeInsets.all(tokens.spacing.md),
      semanticLabel: 'Cards',
      tileBuilder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cards',
              style: tokens.typography.tileSubtitle.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${value.length}',
                  style: tokens.typography.metric.copyWith(
                    color: tokens.color.textPrimary,
                  ),
                ),
                Text(
                  'active',
                  style: tokens.typography.caption.copyWith(
                    color: tokens.color.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class InsightTile extends StatelessWidget implements MosaicTileWidget {
  const InsightTile({super.key, required this.weeklySpend});

  @override
  MosaicTileSize get size => MosaicTileSize.medium;

  final ValueListenable<int> weeklySpend;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicLiveTile<int>(
      size: MosaicTileSize.medium,
      source: MosaicLiveSource<int>.fromListenable(weeklySpend),
      padding: EdgeInsets.all(tokens.spacing.md),
      semanticLabel: 'Weekly spend',
      tileBuilder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly spend',
              style: tokens.typography.tileSubtitle.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
            Text(
              formatCents(value),
              style: tokens.typography.title.copyWith(
                color: tokens.color.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}
