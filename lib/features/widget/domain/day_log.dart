import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter/foundation.dart' show immutable;

/// What the widget draws: today's fixes, and the latest fix of any day.
@immutable
class DayTrail {
  const DayTrail({required this.today, required this.last});

  final List<Fix> today;
  final Fix? last;
}

/// The widget's own record of the day. The tracker's queue cannot be used: it deletes points once uploaded.
abstract interface class DayLog {
  Future<void> append(Fix f);
  Future<DayTrail> read(DateTime now);
  Future<void> clear();
}

/// Same calendar day on this phone.
bool sameLocalDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}
