/// Service for XP and leveling calculations
class ExperienceService {
  /// Experience groups and their total XP to reach level 100
  static const Map<String, String> groupDescriptions = {
    'erratic': 'Erratic (600,000 XP to Lv100)',
    'fast': 'Fast (800,000 XP to Lv100)',
    'medium-fast': 'Medium Fast (1,000,000 XP to Lv100)',
    'medium-slow': 'Medium Slow (1,059,860 XP to Lv100)',
    'slow': 'Slow (1,250,000 XP to Lv100)',
    'fluctuating': 'Fluctuating (1,640,000 XP to Lv100)',
  };

  /// Calculate total XP needed to reach a given level for each growth rate
  static int totalXPForLevel(String growthRate, int level) {
    if (level <= 1) return 0;
    if (level > 100) level = 100;
    final n = level;

    switch (growthRate) {
      case 'erratic':
        if (n <= 50) return (n * n * n * (100 - n)) ~/ 50;
        if (n <= 68) return (n * n * n * (150 - n)) ~/ 100;
        if (n <= 98) return (n * n * n * ((1911 - 10 * n) ~/ 3)) ~/ 500;
        return (n * n * n * (160 - n)) ~/ 100;

      case 'fast':
        return (4 * n * n * n) ~/ 5;

      case 'medium-fast':
        return n * n * n;

      case 'medium-slow':
        return ((6 * n * n * n) ~/ 5) - (15 * n * n) + (100 * n) - 140;

      case 'slow':
        return (5 * n * n * n) ~/ 4;

      case 'fluctuating':
        if (n <= 15) return (n * n * n * ((((n + 1) / 3).floor() + 24) ~/ 1)) ~/ 50;
        if (n <= 36) return (n * n * n * (n + 14)) ~/ 50;
        return (n * n * n * ((n ~/ 2) + 32)) ~/ 50;

      default:
        return n * n * n;
    }
  }

  /// Calculate XP needed to go from one level to the next
  static int xpBetweenLevels(String growthRate, int fromLevel, int toLevel) {
    return totalXPForLevel(growthRate, toLevel) - totalXPForLevel(growthRate, fromLevel);
  }

  /// Get a table of XP per level for a growth rate
  static List<Map<String, dynamic>> getXPTable(String growthRate, {int fromLevel = 1, int toLevel = 100}) {
    final table = <Map<String, dynamic>>[];
    for (int level = fromLevel; level <= toLevel; level++) {
      final totalXP = totalXPForLevel(growthRate, level);
      final nextXP = level < 100 ? totalXPForLevel(growthRate, level + 1) : totalXP;
      table.add({
        'level': level,
        'totalXP': totalXP,
        'xpToNext': level < 100 ? nextXP - totalXP : 0,
      });
    }
    return table;
  }

  static const List<String> allGrowthRates = [
    'erratic', 'fast', 'medium-fast', 'medium-slow', 'slow', 'fluctuating',
  ];
}
