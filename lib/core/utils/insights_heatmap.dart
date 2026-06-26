// Recall · Insights heatmap presentation util. Pure mapping of the server-owned
// `v_daily_activity` series into the 12-week × 7-day grid the `Heatmap` widget
// renders (levels 0..4 on the 5-stop monochrome scale). No business metrics are
// computed here — only fixed display thresholds on review_count.

import '../../data/models/daily_activity.dart';

class InsightsHeatmap {
  const InsightsHeatmap._();

  static const int weeks = 12;
  static const int daysPerWeek = 7;

  /// Map a daily review count to a 0..4 intensity stop. Fixed, calm thresholds
  /// (presentation only): 0 / 1 / 2-3 / 4-7 / 8+.
  static int levelFor(int reviewCount) {
    if (reviewCount <= 0) return 0;
    if (reviewCount == 1) return 1;
    if (reviewCount <= 3) return 2;
    if (reviewCount <= 7) return 3;
    return 4;
  }

  /// Build a `weeks × 7` grid of intensity levels ending today. Columns are
  /// weeks (oldest → newest, left → right); rows are weekdays (Mon → Sun top →
  /// bottom). Missing days render as level 0.
  static List<List<int>> build(List<DailyActivity> activity, {DateTime? today}) {
    final now = (today ?? DateTime.now()).toUtc();
    final todayDate = DateTime.utc(now.year, now.month, now.day);

    // Index counts by yyyy-mm-dd for O(1) lookup.
    final counts = <String, int>{};
    for (final a in activity) {
      final d = a.activityDate.toUtc();
      counts[_key(DateTime.utc(d.year, d.month, d.day))] = a.reviewCount;
    }

    // The grid's last column ends on the week containing today; align so today
    // sits in the final column at its weekday row.
    final mondayOffset = (todayDate.weekday - DateTime.monday) % 7;
    final lastColMonday = todayDate.subtract(Duration(days: mondayOffset));
    final firstColMonday =
        lastColMonday.subtract(const Duration(days: (weeks - 1) * 7));

    return List.generate(weeks, (col) {
      final colMonday = firstColMonday.add(Duration(days: col * 7));
      return List.generate(daysPerWeek, (row) {
        final cellDate = colMonday.add(Duration(days: row));
        if (cellDate.isAfter(todayDate)) return 0;
        return levelFor(counts[_key(cellDate)] ?? 0);
      });
    });
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
