String formatCents(int cents, {bool withSign = false}) {
  final isNegative = cents < 0;
  final abs = cents.abs();
  final shillings = abs ~/ 100;
  final fraction = abs % 100;
  final buf = StringBuffer();
  final s = shillings.toString();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  final sign = isNegative ? '-' : (withSign ? '+' : '');
  return '${sign}KES $buf.${fraction.toString().padLeft(2, '0')}';
}

String formatRelative(DateTime when) {
  final now = DateTime(2026, 5, 2, 14, 30);
  final diff = now.difference(when);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${when.day}/${when.month}';
}
