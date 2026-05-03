import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'format.dart';
import 'wallet_data.dart';

/// Shared chrome for every wallet panel: back affordance, title, body.
class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final scope = MosaicSurfaceScope.of(context);
    return MosaicPanel(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.md,
        vertical: tokens.spacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BackButton(onPressed: scope.pop),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Text(
                  title,
                  style: tokens.typography.title.copyWith(
                    color: tokens.color.textPrimary,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicPressFeedback(
      onPressed: onPressed,
      semanticLabel: 'Collapse panel',
      child: MosaicSurface(
        kind: MosaicSurfaceKind.muted,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sm,
          vertical: tokens.spacing.xs,
        ),
        child: Text(
          '←',
          textAlign: TextAlign.center,
          style: tokens.typography.title.copyWith(
            color: tokens.color.textPrimary,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicPressFeedback(
      onPressed: onPressed,
      enabled: enabled,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: tokens.color.accent,
          borderRadius: BorderRadius.circular(tokens.radius.input),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: tokens.typography.tileTitle.copyWith(
            color: tokens.color.textInverse,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Transaction detail
// ----------------------------------------------------------------------

class TransactionDetailPanel extends StatelessWidget {
  const TransactionDetailPanel({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final tx = transaction;
    final isCredit = tx.amount > 0;
    return _PanelFrame(
      title: 'Transaction',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx.label,
              style: tokens.typography.tileSubtitle.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              formatCents(tx.amount, withSign: true),
              style: tokens.typography.display.copyWith(
                color: isCredit
                    ? tokens.color.success
                    : tokens.color.textPrimary,
              ),
            ),
            SizedBox(height: tokens.spacing.lg),
            _DetailRow(label: 'Date', value: _formatFullDate(tx.when)),
            _DetailRow(label: 'Category', value: tx.category.label),
            if (tx.cardLastFour != null)
              _DetailRow(label: 'Card', value: '••${tx.cardLastFour}'),
            _DetailRow(label: 'Type', value: _formatKind(tx.kind)),
            if (tx.note != null && tx.note!.isNotEmpty)
              _DetailRow(label: 'Note', value: tx.note!),
            SizedBox(height: tokens.spacing.lg),
            Wrap(
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.xs,
              children: [
                MosaicChip(label: 'Split', selected: false, onPressed: () {}),
                MosaicChip(label: 'Repeat', selected: false, onPressed: () {}),
                MosaicChip(label: 'Dispute', selected: false, onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: tokens.typography.caption.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tokens.typography.body.copyWith(
                color: tokens.color.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatKind(TransactionKind kind) => switch (kind) {
  TransactionKind.debit => 'Debit',
  TransactionKind.credit => 'Credit',
  TransactionKind.transfer => 'Transfer',
};

String _formatFullDate(DateTime when) {
  final h = when.hour.toString().padLeft(2, '0');
  final m = when.minute.toString().padLeft(2, '0');
  return '${when.day}/${when.month}/${when.year} · $h:$m';
}

// ----------------------------------------------------------------------
// Card detail
// ----------------------------------------------------------------------

class CardDetailPanel extends StatelessWidget {
  const CardDetailPanel({
    super.key,
    required this.lastFour,
    required this.cards,
    required this.transactions,
    required this.color,
    required this.onToggleFrozen,
  });

  final String lastFour;
  final ValueListenable<List<WalletCard>> cards;
  final ValueListenable<List<Transaction>> transactions;
  final Color color;
  final VoidCallback onToggleFrozen;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return _PanelFrame(
      title: 'Card',
      child: SingleChildScrollView(
        child: ValueListenableBuilder<List<WalletCard>>(
          valueListenable: cards,
          builder: (context, list, _) {
            final card = list.firstWhere(
              (c) => c.lastFour == lastFour,
              orElse: () => list.first,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardHero(card: card, color: color),
                SizedBox(height: tokens.spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: MosaicChip(
                        label: card.frozen ? 'Frozen' : 'Active',
                        selected: card.frozen,
                        onPressed: onToggleFrozen,
                        glyph: card.frozen ? '◌' : '●',
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sm),
                    Expanded(
                      child: MosaicChip(
                        label: 'Limits',
                        selected: false,
                        onPressed: () {},
                        glyph: '⏚',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacing.md),
                Text(
                  'Activity on this card',
                  style: tokens.typography.tileSubtitle.copyWith(
                    color: tokens.color.textSecondary,
                  ),
                ),
                ValueListenableBuilder<List<Transaction>>(
                  valueListenable: transactions,
                  builder: (context, txs, _) {
                    final filtered = txs
                        .where((t) => t.cardLastFour == lastFour)
                        .take(5)
                        .toList();
                    if (filtered.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(tokens.spacing.md),
                        child: Text(
                          'No transactions on this card',
                          style: tokens.typography.body.copyWith(
                            color: tokens.color.textSecondary,
                          ),
                        ),
                      );
                    }
                    return MosaicList(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      rows: [
                        for (final tx in filtered)
                          MosaicListRow(
                            title: tx.label,
                            subtitle: tx.category.label,
                            trailing: Text(
                              formatCents(tx.amount, withSign: true),
                              style: tokens.typography.body.copyWith(
                                color: tx.amount < 0
                                    ? tokens.color.textPrimary
                                    : tokens.color.success,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CardHero extends StatelessWidget {
  const _CardHero({required this.card, required this.color});

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
                Text(
                  '${formatCents(card.spent)} · ${formatCents(card.limit)}',
                  style: tokens.typography.caption.copyWith(
                    color: ink.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (card.frozen)
            Positioned.fill(
              child: ColoredBox(
                color: tokens.color.background.withValues(alpha: 0.6),
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

// ----------------------------------------------------------------------
// Send
// ----------------------------------------------------------------------

class SendPanel extends StatefulWidget {
  const SendPanel({super.key, required this.balance, required this.onSend});

  final ValueListenable<int> balance;
  final void Function(String recipient, int amountCents, String? note) onSend;

  @override
  State<SendPanel> createState() => _SendPanelState();
}

class _SendPanelState extends State<SendPanel> {
  final _recipient = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recipient.addListener(_rebuild);
    _amount.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _recipient.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? _amountCents() {
    final raw = _amount.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null) return null;
    return (value * 100).round();
  }

  bool get _canSubmit {
    if (_recipient.text.trim().isEmpty) return false;
    final cents = _amountCents();
    return cents != null && cents > 0 && cents <= widget.balance.value;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final scope = MosaicSurfaceScope.of(context);
    return _PanelFrame(
      title: 'Send',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: widget.balance,
              builder: (context, bal, _) => Text(
                'Available  ${formatCents(bal)}',
                style: tokens.typography.caption.copyWith(
                  color: tokens.color.textSecondary,
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.md),
            MosaicInput(
              controller: _recipient,
              placeholder: 'Recipient',
              autofocus: true,
            ),
            SizedBox(height: tokens.spacing.sm),
            MosaicInput(
              controller: _amount,
              placeholder: 'Amount (KES)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            MosaicInput(controller: _note, placeholder: 'Note (optional)'),
            SizedBox(height: tokens.spacing.lg),
            _PrimaryButton(
              label: 'Send',
              enabled: _canSubmit,
              onPressed: () {
                final cents = _amountCents();
                if (cents == null) return;
                widget.onSend(
                  _recipient.text.trim(),
                  cents,
                  _note.text.trim().isEmpty ? null : _note.text.trim(),
                );
                scope.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Settings
// ----------------------------------------------------------------------

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _notifications = true;
  bool _largeText = false;
  double _dailyLimit = 25000;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final app = MosaicAppScope.of(context);
    return _PanelFrame(
      title: 'Settings',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(label: 'Appearance'),
            MosaicRadioGroup<MosaicMode>(
              value: app.mode,
              onChanged: app.setMode,
              options: const [
                MosaicRadioOption(value: MosaicMode.metro, label: 'Metro'),
                MosaicRadioOption(value: MosaicMode.modern, label: 'Modern'),
              ],
            ),
            SizedBox(height: tokens.spacing.sm),
            MosaicSelect<Brightness>(
              value: app.brightness,
              title: 'Theme',
              options: const [
                MosaicSelectOption(value: Brightness.dark, label: 'Dark'),
                MosaicSelectOption(value: Brightness.light, label: 'Light'),
              ],
              onChanged: app.setBrightness,
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionHeader(label: 'Preferences'),
            MosaicToggle(
              value: _notifications,
              label: 'Notifications',
              onChanged: (v) => setState(() => _notifications = v),
            ),
            MosaicToggle(
              value: _largeText,
              label: 'Larger text',
              onChanged: (v) => setState(() => _largeText = v),
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionHeader(label: 'Limits'),
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daily spend',
                      style: tokens.typography.body.copyWith(
                        color: tokens.color.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatCents(_dailyLimit.round()),
                    style: tokens.typography.body.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            MosaicSlider(
              value: _dailyLimit,
              min: 0,
              max: 200000,
              divisions: 20,
              onChanged: (v) => setState(() => _dailyLimit = v),
            ),
            SizedBox(height: tokens.spacing.lg),
            const _SectionHeader(label: 'Account'),
            MosaicCheckbox(
              value: true,
              onChanged: (_) {},
              label: 'Two-factor authentication',
            ),
            MosaicCheckbox(
              value: false,
              onChanged: (_) {},
              label: 'Biometric unlock',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: tokens.spacing.xs,
        bottom: tokens.spacing.sm,
      ),
      child: Text(
        label,
        style: tokens.typography.tileSubtitle.copyWith(
          color: tokens.color.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Pay
// ----------------------------------------------------------------------

class PayPanel extends StatefulWidget {
  const PayPanel({
    super.key,
    required this.balance,
    required this.transactions,
    required this.onPay,
  });

  final ValueListenable<int> balance;
  final ValueListenable<List<Transaction>> transactions;
  final void Function(String merchant, int amountCents) onPay;

  @override
  State<PayPanel> createState() => _PayPanelState();
}

class _PayPanelState extends State<PayPanel> {
  final _amount = TextEditingController();
  String? _selectedMerchant;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? _amountCents() {
    final raw = _amount.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null) return null;
    return (value * 100).round();
  }

  bool get _canSubmit {
    final cents = _amountCents();
    return _selectedMerchant != null &&
        cents != null &&
        cents > 0 &&
        cents <= widget.balance.value;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final scope = MosaicSurfaceScope.of(context);
    return _PanelFrame(
      title: 'Pay',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MosaicSurface(
              kind: MosaicSurfaceKind.muted,
              padding: EdgeInsets.all(tokens.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan to pay',
                    style: tokens.typography.tileSubtitle.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.color.surface,
                        borderRadius: BorderRadius.circular(tokens.radius.tile),
                      ),
                      child: Center(
                        child: Text(
                          '⌗',
                          style: TextStyle(
                            fontSize: 96,
                            color: tokens.color.textSecondary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spacing.md),
            Text(
              'Recent merchants',
              style: tokens.typography.tileSubtitle.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            ValueListenableBuilder<List<Transaction>>(
              valueListenable: widget.transactions,
              builder: (context, txs, _) {
                final unique = <String>{
                  for (final t in txs)
                    if (t.amount < 0) t.label,
                };
                final merchants = unique.take(6).toList();
                if (merchants.isEmpty) {
                  return Text(
                    'No recent merchants',
                    style: tokens.typography.body.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  );
                }
                return Wrap(
                  spacing: tokens.spacing.sm,
                  runSpacing: tokens.spacing.xs,
                  children: [
                    for (final m in merchants)
                      MosaicChip(
                        label: m,
                        selected: m == _selectedMerchant,
                        onPressed: () => setState(() => _selectedMerchant = m),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: tokens.spacing.md),
            MosaicInput(
              controller: _amount,
              placeholder: 'Amount (KES)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            SizedBox(height: tokens.spacing.lg),
            _PrimaryButton(
              label: 'Pay',
              enabled: _canSubmit,
              onPressed: () {
                final cents = _amountCents();
                if (cents == null || _selectedMerchant == null) return;
                widget.onPay(_selectedMerchant!, cents);
                scope.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
