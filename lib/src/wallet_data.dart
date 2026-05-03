import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum TransactionKind { debit, credit, transfer }

enum TransactionCategory {
  food('Food'),
  transport('Transport'),
  shopping('Shopping'),
  bills('Bills'),
  entertainment('Entertainment'),
  income('Income'),
  other('Other');

  const TransactionCategory(this.label);
  final String label;
}

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.label,
    required this.amount,
    required this.when,
    required this.kind,
    required this.category,
    this.cardLastFour,
    this.note,
  });

  final String id;
  final String label;

  /// Amount in cents. Negative for debits, positive for credits.
  final int amount;

  final DateTime when;
  final TransactionKind kind;
  final TransactionCategory category;
  final String? cardLastFour;
  final String? note;
}

@immutable
class WalletCard {
  const WalletCard({
    required this.label,
    required this.lastFour,
    required this.spent,
    required this.limit,
    this.frozen = false,
  });

  final String label;
  final String lastFour;
  final int spent;
  final int limit;
  final bool frozen;

  double get utilization => limit == 0 ? 0 : spent / limit;

  WalletCard copyWith({bool? frozen}) => WalletCard(
    label: label,
    lastFour: lastFour,
    spent: spent,
    limit: limit,
    frozen: frozen ?? this.frozen,
  );
}

/// Single source of fake live data the demo binds to. A real app would
/// replace this with a domain layer; the boundary is the same shape
/// (ValueListenable / Stream) that MosaicLiveSource accepts directly.
class WalletData {
  WalletData() {
    _seed();
  }

  final ValueNotifier<int> balance = ValueNotifier<int>(0);
  final ValueNotifier<List<Transaction>> transactions =
      ValueNotifier<List<Transaction>>(const []);
  final ValueNotifier<List<WalletCard>> cards = ValueNotifier<List<WalletCard>>(
    const [],
  );
  final ValueNotifier<int> weeklySpend = ValueNotifier<int>(0);

  Timer? _ticker;
  final Random _rng = Random(42);

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  void dispose() {
    _ticker?.cancel();
    balance.dispose();
    transactions.dispose();
    cards.dispose();
    weeklySpend.dispose();
  }

  void toggleCardFrozen(String lastFour) {
    cards.value = [
      for (final c in cards.value)
        if (c.lastFour == lastFour) c.copyWith(frozen: !c.frozen) else c,
    ];
  }

  /// Simulates a successful send. Posts a debit and shrinks the balance.
  void recordSend({
    required String recipient,
    required int amountCents,
    String? note,
  }) {
    final tx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      label: 'To $recipient',
      amount: -amountCents,
      when: DateTime.now(),
      kind: TransactionKind.transfer,
      category: TransactionCategory.other,
      note: note,
    );
    balance.value = balance.value - amountCents;
    transactions.value = [tx, ...transactions.value].take(20).toList();
  }

  /// Simulates a successful pay. Posts a debit.
  void recordPay({required String merchant, required int amountCents}) {
    final tx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      label: merchant,
      amount: -amountCents,
      when: DateTime.now(),
      kind: TransactionKind.debit,
      category: TransactionCategory.shopping,
    );
    balance.value = balance.value - amountCents;
    weeklySpend.value = weeklySpend.value + amountCents;
    transactions.value = [tx, ...transactions.value].take(20).toList();
  }

  void _seed() {
    final now = DateTime(2026, 5, 2, 14, 30);
    balance.value = 1245000;
    transactions.value = <Transaction>[
      Transaction(
        id: 'tx_001',
        label: 'Java House',
        amount: -45000,
        when: now.subtract(const Duration(hours: 2)),
        kind: TransactionKind.debit,
        category: TransactionCategory.food,
        cardLastFour: '4421',
      ),
      Transaction(
        id: 'tx_002',
        label: 'Salary — Acme Co.',
        amount: 850000,
        when: now.subtract(const Duration(days: 1)),
        kind: TransactionKind.credit,
        category: TransactionCategory.income,
      ),
      Transaction(
        id: 'tx_003',
        label: 'Uber',
        amount: -28000,
        when: now.subtract(const Duration(days: 1, hours: 6)),
        kind: TransactionKind.debit,
        category: TransactionCategory.transport,
        cardLastFour: '4421',
      ),
      Transaction(
        id: 'tx_004',
        label: 'Naivas Supermarket',
        amount: -312000,
        when: now.subtract(const Duration(days: 2)),
        kind: TransactionKind.debit,
        category: TransactionCategory.shopping,
        cardLastFour: '4421',
      ),
      Transaction(
        id: 'tx_005',
        label: 'Netflix',
        amount: -160000,
        when: now.subtract(const Duration(days: 3)),
        kind: TransactionKind.debit,
        category: TransactionCategory.entertainment,
        cardLastFour: '4421',
      ),
      Transaction(
        id: 'tx_006',
        label: 'KPLC — Electricity',
        amount: -240000,
        when: now.subtract(const Duration(days: 4)),
        kind: TransactionKind.debit,
        category: TransactionCategory.bills,
        cardLastFour: '4421',
      ),
      Transaction(
        id: 'tx_007',
        label: 'Refund — Bolt',
        amount: 18000,
        when: now.subtract(const Duration(days: 5)),
        kind: TransactionKind.credit,
        category: TransactionCategory.transport,
        cardLastFour: '4421',
      ),
    ];
    cards.value = const <WalletCard>[
      WalletCard(
        label: 'Daily',
        lastFour: '4421',
        spent: 320000,
        limit: 500000,
      ),
      WalletCard(
        label: 'Travel',
        lastFour: '9988',
        spent: 12500,
        limit: 200000,
      ),
    ];
    weeklySpend.value = 487000;
  }

  void _tick() {
    final merchants = <(String, TransactionCategory)>[
      ('Starbucks', TransactionCategory.food),
      ('Uber', TransactionCategory.transport),
      ('Java House', TransactionCategory.food),
      ('Naivas', TransactionCategory.shopping),
      ('Bolt', TransactionCategory.transport),
      ('Carrefour', TransactionCategory.shopping),
      ('Pizza Inn', TransactionCategory.food),
    ];
    final pick = merchants[_rng.nextInt(merchants.length)];
    final amount = -(2000 + _rng.nextInt(60000));
    final tx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      label: pick.$1,
      amount: amount,
      when: DateTime.now(),
      kind: TransactionKind.debit,
      category: pick.$2,
      cardLastFour: '4421',
    );
    balance.value = balance.value + amount;
    weeklySpend.value = weeklySpend.value - amount;
    final next = <Transaction>[tx, ...transactions.value];
    transactions.value = next.length > 20 ? next.sublist(0, 20) : next;
  }
}
