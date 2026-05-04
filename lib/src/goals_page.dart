import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'format.dart';
import 'wallet_data.dart';

/// Goals pivot tab. Lists each saving goal with its progress, target,
/// and a Top up action that pulls cents from the balance.
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key, required this.data});

  final WalletData data;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return ValueListenableBuilder<List<WalletGoal>>(
      valueListenable: data.goals,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return MosaicEmptyState(
            title: 'No goals yet',
            body: 'Set a target — emergency fund, trip, gear — '
                'and Mosaic Wallet will track progress here.',
            glyph: '◧',
            actionLabel: 'Add a goal',
            onAction: () {},
          );
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: tokens.spacing.md),
          itemBuilder: (context, i) => _GoalCard(goal: list[i], data: data),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.data});

  final WalletGoal goal;
  final WalletData data;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final percent = (goal.progress * 100).round();
    return MosaicSurface(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (goal.glyph != null) ...[
                MosaicAvatar(
                  child: Text(
                    goal.glyph!,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1,
                      color: tokens.color.accent,
                    ),
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MosaicText.tileTitle(goal.label),
                    SizedBox(height: tokens.spacing.xs),
                    MosaicText.caption(
                      'by ${goal.dueBy.day}/${goal.dueBy.month}/${goal.dueBy.year}',
                    ),
                  ],
                ),
              ),
              MosaicBadge(
                label: '$percent%',
                tone: goal.progress >= 1
                    ? MosaicBadgeTone.success
                    : MosaicBadgeTone.accent,
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          MosaicProgressBar(value: goal.progress, height: 6),
          SizedBox(height: tokens.spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MosaicText.body(formatCents(goal.savedCents)),
              MosaicText.caption('of ${formatCents(goal.targetCents)}'),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          MosaicButton(
            label: 'Top up KES 5,000',
            onPressed: () => data.contributeToGoal(goal.label, 500000),
            kind: MosaicButtonKind.secondary,
            expand: false,
          ),
        ],
      ),
    );
  }
}
