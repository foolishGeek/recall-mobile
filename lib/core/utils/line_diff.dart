// A tiny line-level diff used by the AI evaluation "review suggestion" view.
//
// It computes the longest-common-subsequence of lines between the original note
// and Aura's suggested rewrite, then walks both sides to label each line as
// kept (equal), removed (only in original), or added (only in suggestion). This
// is enough for a calm, git-style read-only diff — no inline word highlighting,
// which keeps the surface low-cortisol.

enum DiffOp { equal, removed, added }

class DiffLine {
  final DiffOp op;
  final String text;

  const DiffLine(this.op, this.text);
}

class LineDiff {
  const LineDiff._();

  /// Splits on newlines, preserving blank lines so paragraph spacing survives.
  static List<String> _lines(String s) => s.replaceAll('\r\n', '\n').split('\n');

  /// Computes a line-level diff between [before] and [after].
  static List<DiffLine> compute(String before, String after) {
    final a = _lines(before);
    final b = _lines(after);
    final n = a.length;
    final m = b.length;

    // LCS table — lcs[i][j] = length of longest common subsequence of a[i:] and
    // b[j:]. Built bottom-up so we can backtrack from the top-left.
    final lcs = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        if (a[i] == b[j]) {
          lcs[i][j] = lcs[i + 1][j + 1] + 1;
        } else {
          lcs[i][j] = lcs[i + 1][j] >= lcs[i][j + 1]
              ? lcs[i + 1][j]
              : lcs[i][j + 1];
        }
      }
    }

    final out = <DiffLine>[];
    var i = 0;
    var j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        out.add(DiffLine(DiffOp.equal, a[i]));
        i++;
        j++;
      } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        out.add(DiffLine(DiffOp.removed, a[i]));
        i++;
      } else {
        out.add(DiffLine(DiffOp.added, b[j]));
        j++;
      }
    }
    while (i < n) {
      out.add(DiffLine(DiffOp.removed, a[i]));
      i++;
    }
    while (j < m) {
      out.add(DiffLine(DiffOp.added, b[j]));
      j++;
    }
    return out;
  }

  /// True when the suggestion is meaningfully different from the original.
  static bool hasChanges(String before, String after) {
    return before.trim() != after.trim();
  }
}
