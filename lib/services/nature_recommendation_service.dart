/// Service that recommends the best competitive nature for any Pokemon
/// by analyzing its base stats. Works for all Pokemon across all generations.
class NatureRecommendationService {
  /// Returns a list of recommended natures with reasoning for the given Pokemon.
  /// Each entry is a map with 'nature', 'reason', and 'role' keys.
  /// Analyzes base stats to determine the optimal nature automatically.
  static List<Map<String, String>> getRecommendedNatures(
    String pokemonName,
    Map<String, int> baseStats,
  ) {
    final key = pokemonName.toLowerCase().replaceAll(' ', '-').replaceAll('.', '').replaceAll("'", '');

    // Check overrides for special cases where stats alone are misleading
    if (_specialOverrides.containsKey(key)) {
      return _specialOverrides[key]!;
    }

    return _analyzeStats(baseStats);
  }

  static List<Map<String, String>> _analyzeStats(Map<String, int> stats) {
    final atk = stats['Attack'] ?? 0;
    final spa = stats['Sp. Atk'] ?? 0;
    final def = stats['Defense'] ?? 0;
    final spd = stats['Sp. Def'] ?? 0;
    final spe = stats['Speed'] ?? 0;
    final hp = stats['HP'] ?? 0;
    final bst = atk + spa + def + spd + spe + hp;

    final results = <Map<String, String>>[];

    final bool isPhysical = atk > spa + 15;
    final bool isSpecial = spa > atk + 15;
    final bool isMixed = !isPhysical && !isSpecial && atk >= 70 && spa >= 70;
    final bool isFast = spe >= 80;
    final bool isSlow = spe <= 50;
    final bool isBulky = (def + spd + hp) > (atk + spa + spe);
    final bool isPhysicalWall = def > spd + 20 && isBulky;
    final bool isSpecialWall = spd > def + 20 && isBulky;
    final bool isVeryWeak = bst < 300;

    // Very low BST Pokemon (baby / unevolved) — just pick based on highest stat
    if (isVeryWeak) {
      if (atk >= spa && atk >= spe) {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
      } else if (spa >= atk && spa >= spe) {
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special Attacker'});
      } else {
        results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Attacker'});
      }
      return results;
    }

    if (isPhysical) {
      if (isFast) {
        results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'});
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Power Physical Attacker'});
      } else if (isSlow) {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
        results.add({'nature': 'Brave', 'reason': '+Attack / -Speed', 'role': 'Trick Room Attacker'});
      } else {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
        results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'});
      }
    } else if (isSpecial) {
      if (isFast) {
        results.add({'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker'});
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Power Special Attacker'});
      } else if (isSlow) {
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special Attacker'});
        results.add({'nature': 'Quiet', 'reason': '+Sp. Atk / -Speed', 'role': 'Trick Room Special Attacker'});
      } else {
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special Attacker'});
        results.add({'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker'});
      }
    } else if (isBulky) {
      if (isPhysicalWall) {
        results.add({'nature': 'Impish', 'reason': '+Defense / -Sp. Atk', 'role': 'Physical Wall'});
        results.add({'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physical Wall (Special moves)'});
      } else if (isSpecialWall) {
        results.add({'nature': 'Careful', 'reason': '+Sp. Def / -Sp. Atk', 'role': 'Special Wall'});
        results.add({'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Special Wall (Special moves)'});
      } else {
        if (atk >= spa) {
          results.add({'nature': 'Impish', 'reason': '+Defense / -Sp. Atk', 'role': 'Defensive (Physical moves)'});
          results.add({'nature': 'Careful', 'reason': '+Sp. Def / -Sp. Atk', 'role': 'Specially Defensive'});
        } else {
          results.add({'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Defensive (Special moves)'});
          results.add({'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive'});
        }
      }
    } else if (isMixed) {
      if (isFast) {
        results.add({'nature': 'Naive', 'reason': '+Speed / -Sp. Def', 'role': 'Fast Mixed Attacker'});
        results.add({'nature': 'Hasty', 'reason': '+Speed / -Defense', 'role': 'Fast Mixed Attacker'});
      } else {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical-leaning Mixed'});
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special-leaning Mixed'});
      }
    } else {
      // Generic fallback
      if (atk >= spa) {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
        if (isFast) {
          results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'});
        }
      } else {
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special Attacker'});
        if (isFast) {
          results.add({'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker'});
        }
      }
    }

    return results;
  }

  /// Overrides only for Pokemon where stat analysis gives misleading results
  /// (e.g. stance-change mechanics, transform, unique roles).
  static const Map<String, List<Map<String, String>>> _specialOverrides = {
    'ditto': [
      {'nature': 'Jolly', 'reason': 'Any — Ditto copies the target', 'role': 'Imposter (nature irrelevant)'},
    ],
    'aegislash': [
      {'nature': 'Quiet', 'reason': '+Sp. Atk / -Speed', 'role': 'Special Attacker (Stance Change)'},
      {'nature': 'Brave', 'reason': '+Attack / -Speed', 'role': 'Physical Attacker (Stance Change)'},
      {'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Swords Dance'},
    ],
    'shuckle': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Defensive (Sticky Web / Stealth Rock)'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive'},
    ],
    'smeargle': [
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Lead (Spore / Sticky Web)'},
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Lead'},
    ],
    'wobbuffet': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Counter Wall'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Mirror Coat Wall'},
    ],
    'shedinja': [
      {'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker (Wonder Guard)'},
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Attacker (Wonder Guard)'},
    ],
    'castform': [
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Weather Special Attacker'},
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Weather Attacker'},
    ],
    'zorua': [
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker (Illusion)'},
    ],
    'zoroark': [
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker (Illusion)'},
      {'nature': 'Naive', 'reason': '+Speed / -Sp. Def', 'role': 'Mixed Attacker (Illusion)'},
    ],
  };
}
