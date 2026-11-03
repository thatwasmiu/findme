/// Vietnamese time words, as on the web (`trail.ts`, `SharePanel.tsx`).
library;

/// "vừa xong", "12 phút trước", "3 giờ trước", "2 ngày trước".
String ago(String iso, {DateTime? now}) {
  final ms = (now ?? DateTime.now())
      .difference(DateTime.parse(iso))
      .inMilliseconds;
  final min = (ms / 60000).round();
  if (min < 1) return 'vừa xong';
  if (min < 60) return '$min phút trước';
  final h = (min / 60).round();
  if (h < 24) return '$h giờ trước';
  return '${(h / 24).round()} ngày trước';
}

/// "45 phút", "2 giờ 10 phút".
String duration(int seconds) {
  final min = (seconds / 60).round().clamp(1, 1 << 31);
  if (min < 60) return '$min phút';
  final h = min ~/ 60, m = min % 60;
  return m > 0 ? '$h giờ $m phút' : '$h giờ';
}

/// "còn 25 phút", "còn 5 giờ", "còn 3 ngày", "đã hết hạn".
String remaining(String iso, {DateTime? now}) {
  final ms = DateTime.parse(iso)
      .difference(now ?? DateTime.now())
      .inMilliseconds;
  if (ms <= 0) return 'đã hết hạn';
  final min = (ms / 60000).ceil();
  if (min < 60) return 'còn $min phút';
  final h = (min / 60).round();
  if (h < 24) return 'còn $h giờ';
  return 'còn ${(h / 24).round()} ngày';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Local 24 h "HH:mm".
String hhmm(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// [hhmm] for an ISO string or epoch seconds.
String hhmmIso(String iso) => hhmm(DateTime.parse(iso));
String hhmmSec(num epochSec) =>
    hhmm(DateTime.fromMillisecondsSinceEpoch((epochSec * 1000).round()));

/// "YYYY-MM-DD" → "DD/MM".
String dm(String ymd) => '${ymd.substring(8, 10)}/${ymd.substring(5, 7)}';

/// Local "dd/MM" of epoch seconds.
String dayMonth(num epochSec) {
  final d = DateTime.fromMillisecondsSinceEpoch((epochSec * 1000).round());
  return '${_two(d.day)}/${_two(d.month)}';
}

/// Local "YYYY-MM-DD".
String ymd(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)}';
}
