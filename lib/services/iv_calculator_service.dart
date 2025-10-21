class IVCalculatorService {
  /// Calculate possible IV range for a stat given observed values
  static Map<String, int> calculateIVRange({
    required int baseStat,
    required int observedStat,
    required int level,
    required int ev,
    required double natureModifier,
    required bool isHP,
  }) {
    int minIV = 0;
    int maxIV = 31;

    // Try each possible IV and see if it produces the observed stat
    for (int iv = 0; iv <= 31; iv++) {
      int calculatedStat = calculateSingleStat(
        baseStat: baseStat,
        iv: iv,
        ev: ev,
        level: level,
        natureModifier: natureModifier,
        isHP: isHP,
      );

      if (calculatedStat == observedStat) {
        if (iv < minIV || minIV == 0) minIV = iv;
        if (iv > maxIV || maxIV == 31) maxIV = iv;
      }
    }

    // If we found valid IVs, return the range
    // Otherwise, try to find closest matches
    if (minIV <= maxIV && minIV != 0) {
      return {'min': minIV, 'max': maxIV};
    }

    // No exact match found, find closest possible
    int closestIV = _findClosestIV(
      baseStat: baseStat,
      observedStat: observedStat,
      level: level,
      ev: ev,
      natureModifier: natureModifier,
      isHP: isHP,
    );

    return {'min': closestIV, 'max': closestIV, 'approximate': 1};
  }

  /// Find the IV that produces the closest stat to observed
  static int _findClosestIV({
    required int baseStat,
    required int observedStat,
    required int level,
    required int ev,
    required double natureModifier,
    required bool isHP,
  }) {
    int closestIV = 0;
    int smallestDiff = 999999;

    for (int iv = 0; iv <= 31; iv++) {
      int calculatedStat = calculateSingleStat(
        baseStat: baseStat,
        iv: iv,
        ev: ev,
        level: level,
        natureModifier: natureModifier,
        isHP: isHP,
      );

      int diff = (calculatedStat - observedStat).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closestIV = iv;
      }
    }

    return closestIV;
  }

  /// Calculate a single stat value (forward calculation)
  static int calculateSingleStat({
    required int baseStat,
    required int iv,
    required int ev,
    required int level,
    required double natureModifier,
    required bool isHP,
  }) {
    if (baseStat == 0) return 0;

    int finalStat;
    if (isHP) {
      // HP formula: ((2 * Base + IV + (EV / 4)) * Level / 100) + Level + 10
      finalStat =
          (((2 * baseStat + iv + (ev / 4)) * level) / 100).floor() + level + 10;
    } else {
      // Other stats: (((2 * Base + IV + (EV / 4)) * Level / 100) + 5) * Nature
      finalStat = ((((2 * baseStat + iv + (ev / 4)) * level) / 100) + 5).floor();
      finalStat = (finalStat * natureModifier).floor();
    }
    return finalStat;
  }

  /// Calculate all stats given IVs and EVs
  static Map<String, int> calculateAllStats({
    required Map<String, int> baseStats,
    required Map<String, int> ivs,
    required Map<String, int> evs,
    required int level,
    required String nature,
  }) {
    final natureModifiers = getNatureModifiers(nature);
    final calculatedStats = <String, int>{};

    final statNames = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];

    for (var statName in statNames) {
      final baseStat = baseStats[statName] ?? 0;
      final iv = ivs[statName] ?? 0;
      final ev = evs[statName] ?? 0;
      final natureModifier = natureModifiers[statName] ?? 1.0;
      final isHP = statName == 'HP';

      calculatedStats[statName] = calculateSingleStat(
        baseStat: baseStat,
        iv: iv,
        ev: ev,
        level: level,
        natureModifier: natureModifier,
        isHP: isHP,
      );
    }

    return calculatedStats;
  }

  /// Reverse calculate IVs from observed stats
  static Map<String, Map<String, int>> reverseCalculateIVs({
    required Map<String, int> baseStats,
    required Map<String, int> observedStats,
    required int level,
    required Map<String, int> evs,
    required String nature,
  }) {
    final natureModifiers = getNatureModifiers(nature);
    final ivRanges = <String, Map<String, int>>{};

    final statNames = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];

    for (var statName in statNames) {
      final baseStat = baseStats[statName] ?? 0;
      final observedStat = observedStats[statName] ?? 0;
      final ev = evs[statName] ?? 0;
      final natureModifier = natureModifiers[statName] ?? 1.0;
      final isHP = statName == 'HP';

      ivRanges[statName] = calculateIVRange(
        baseStat: baseStat,
        observedStat: observedStat,
        level: level,
        ev: ev,
        natureModifier: natureModifier,
        isHP: isHP,
      );
    }

    return ivRanges;
  }

  /// Get nature modifiers for all stats
  static Map<String, double> getNatureModifiers(String nature) {
    // Nature effects: 1.1 for increased, 0.9 for decreased, 1.0 for neutral
    final natureEffects = <String, Map<String, double>>{
      'Hardy': {},
      'Lonely': {'Attack': 1.1, 'Defense': 0.9},
      'Brave': {'Attack': 1.1, 'Speed': 0.9},
      'Adamant': {'Attack': 1.1, 'Sp. Atk': 0.9},
      'Naughty': {'Attack': 1.1, 'Sp. Def': 0.9},
      'Bold': {'Defense': 1.1, 'Attack': 0.9},
      'Docile': {},
      'Relaxed': {'Defense': 1.1, 'Speed': 0.9},
      'Impish': {'Defense': 1.1, 'Sp. Atk': 0.9},
      'Lax': {'Defense': 1.1, 'Sp. Def': 0.9},
      'Timid': {'Speed': 1.1, 'Attack': 0.9},
      'Hasty': {'Speed': 1.1, 'Defense': 0.9},
      'Serious': {},
      'Jolly': {'Speed': 1.1, 'Sp. Atk': 0.9},
      'Naive': {'Speed': 1.1, 'Sp. Def': 0.9},
      'Modest': {'Sp. Atk': 1.1, 'Attack': 0.9},
      'Mild': {'Sp. Atk': 1.1, 'Defense': 0.9},
      'Quiet': {'Sp. Atk': 1.1, 'Speed': 0.9},
      'Bashful': {},
      'Rash': {'Sp. Atk': 1.1, 'Sp. Def': 0.9},
      'Calm': {'Sp. Def': 1.1, 'Attack': 0.9},
      'Gentle': {'Sp. Def': 1.1, 'Defense': 0.9},
      'Sassy': {'Sp. Def': 1.1, 'Speed': 0.9},
      'Careful': {'Sp. Def': 1.1, 'Sp. Atk': 0.9},
      'Quirky': {},
    };

    final effects = natureEffects[nature] ?? {};
    return {
      'HP': 1.0,
      'Attack': effects['Attack'] ?? 1.0,
      'Defense': effects['Defense'] ?? 1.0,
      'Sp. Atk': effects['Sp. Atk'] ?? 1.0,
      'Sp. Def': effects['Sp. Def'] ?? 1.0,
      'Speed': effects['Speed'] ?? 1.0,
    };
  }

  /// List of all natures
  static const List<String> allNatures = [
    'Hardy',
    'Lonely',
    'Brave',
    'Adamant',
    'Naughty',
    'Bold',
    'Docile',
    'Relaxed',
    'Impish',
    'Lax',
    'Timid',
    'Hasty',
    'Serious',
    'Jolly',
    'Naive',
    'Modest',
    'Mild',
    'Quiet',
    'Bashful',
    'Rash',
    'Calm',
    'Gentle',
    'Sassy',
    'Careful',
    'Quirky',
  ];

  /// Get stat names
  static const List<String> statNames = [
    'HP',
    'Attack',
    'Defense',
    'Sp. Atk',
    'Sp. Def',
    'Speed'
  ];
}
