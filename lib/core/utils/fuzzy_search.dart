import 'dart:math';

class FuzzySearch {
  /// Calculates Levenshtein distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Calculates Similarity score between 0.0 and 1.0 (1.0 = exact match)
  static double similarityScore(String s1, String s2) {
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();
    if (s1 == s2) return 1.0;
    if (s1.contains(s2) || s2.contains(s1)) return 0.85;

    int distance = levenshteinDistance(s1, s2);
    int maxLength = max(s1.length, s2.length);
    if (maxLength == 0) return 1.0;

    return (1.0 - (distance / maxLength)).clamp(0.0, 1.0);
  }
}
