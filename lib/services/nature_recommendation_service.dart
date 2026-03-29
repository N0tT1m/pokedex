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

    final int offensiveTotal = atk + spa;
    final int defensiveTotal = def + spd + hp;
    final int bestDefense = def > spd ? def : spd;

    final bool leanPhysical = atk > spa + 15;
    final bool leanSpecial = spa > atk + 15;
    final bool isFast = spe >= 85;
    final bool isMidSpeed = spe >= 60 && spe < 85;
    final bool isSlow = spe < 60;

    // Bulk ratio: how much of the stat budget goes to defense
    // A Pokemon with 2:1 defensive-to-offensive ratio is primarily a wall
    final bool isPrimarilyBulky =
        defensiveTotal > offensiveTotal * 1.5 && bestDefense >= 80;
    final bool isPhysicalWall = def >= 100 || (def > spd + 30 && isPrimarilyBulky);
    final bool isSpecialWall = spd >= 100 || (spd > def + 30 && isPrimarilyBulky);

    final bool isMixed = !leanPhysical && !leanSpecial && atk >= 70 && spa >= 70;
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

    // --- Check bulk FIRST so walls don't get offensive natures ---
    if (isPrimarilyBulky) {
      // Determine which offensive stat the Pokemon actually uses
      final bool usesSpecial = leanSpecial || (!leanPhysical && spa > atk);

      if (isPhysicalWall) {
        if (usesSpecial) {
          results.add({'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physical Wall'});
        } else {
          results.add({'nature': 'Impish', 'reason': '+Defense / -Sp. Atk', 'role': 'Physical Wall'});
        }
        if (isSlow) {
          results.add({'nature': 'Relaxed', 'reason': '+Defense / -Speed', 'role': 'Physical Wall (Trick Room)'});
        }
      } else if (isSpecialWall) {
        if (usesSpecial) {
          results.add({'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Special Wall'});
        } else {
          results.add({'nature': 'Careful', 'reason': '+Sp. Def / -Sp. Atk', 'role': 'Special Wall'});
        }
        if (isSlow) {
          results.add({'nature': 'Sassy', 'reason': '+Sp. Def / -Speed', 'role': 'Special Wall (Trick Room)'});
        }
      } else {
        // Balanced wall — recommend both sides
        if (usesSpecial) {
          results.add({'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physically Defensive'});
          results.add({'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive'});
        } else {
          results.add({'nature': 'Impish', 'reason': '+Defense / -Sp. Atk', 'role': 'Physically Defensive'});
          results.add({'nature': 'Careful', 'reason': '+Sp. Def / -Sp. Atk', 'role': 'Specially Defensive'});
        }
      }
      return results;
    }

    // --- Offensive Pokemon ---
    if (leanPhysical) {
      if (isFast) {
        results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'});
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Power Physical Attacker'});
      } else if (isSlow) {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
        results.add({'nature': 'Brave', 'reason': '+Attack / -Speed', 'role': 'Trick Room Attacker'});
      } else {
        // Mid speed — both options are viable
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
        results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'});
      }
    } else if (leanSpecial) {
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
    } else if (isMixed) {
      if (isFast) {
        results.add({'nature': 'Naive', 'reason': '+Speed / -Sp. Def', 'role': 'Fast Mixed Attacker'});
        results.add({'nature': 'Hasty', 'reason': '+Speed / -Defense', 'role': 'Fast Mixed Attacker'});
      } else if (isSlow) {
        if (atk >= spa) {
          results.add({'nature': 'Brave', 'reason': '+Attack / -Speed', 'role': 'Trick Room Mixed (Physical-leaning)'});
          results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical-leaning Mixed'});
        } else {
          results.add({'nature': 'Quiet', 'reason': '+Sp. Atk / -Speed', 'role': 'Trick Room Mixed (Special-leaning)'});
          results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special-leaning Mixed'});
        }
      } else {
        results.add({'nature': 'Naive', 'reason': '+Speed / -Sp. Def', 'role': 'Fast Mixed Attacker'});
        if (atk >= spa) {
          results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical-leaning Mixed'});
        } else {
          results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special-leaning Mixed'});
        }
      }
    } else {
      // Generic fallback — modest offensive stats, not clearly bulky
      if (atk >= spa) {
        results.add({'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker'});
        if (isFast || isMidSpeed) {
          results.add({'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'});
        }
      } else {
        results.add({'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Special Attacker'});
        if (isFast || isMidSpeed) {
          results.add({'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker'});
        }
      }
    }

    return results;
  }

  /// Overrides only for Pokemon where stat analysis gives misleading results
  /// (e.g. stance-change mechanics, transform, unique roles).
  static const Map<String, List<Map<String, String>>> _specialOverrides = {
    // Transform / Copy mechanics
    'ditto': [
      {'nature': 'Jolly', 'reason': 'Any — Ditto copies the target', 'role': 'Imposter (nature irrelevant)'},
    ],
    'mew': [
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Support / Special Attacker'},
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'},
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Defensive Support'},
    ],
    // Stance Change — base form stats are misleading
    'aegislash': [
      {'nature': 'Quiet', 'reason': '+Sp. Atk / -Speed', 'role': 'Special Attacker (Stance Change)'},
      {'nature': 'Brave', 'reason': '+Attack / -Speed', 'role': 'Physical Attacker (Stance Change)'},
      {'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Swords Dance'},
    ],
    // Extreme walls with misleading offensive leans
    'shuckle': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Defensive (Sticky Web / Stealth Rock)'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive'},
    ],
    'chansey': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Eviolite Wall'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive Wall'},
    ],
    'blissey': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Special Wall (shore up Defense)'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Special Wall'},
    ],
    // Support / Lead Pokemon
    'smeargle': [
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Lead (Spore / Sticky Web)'},
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Lead'},
    ],
    'wobbuffet': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Counter Wall'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Mirror Coat Wall'},
    ],
    // 1 HP gimmick
    'shedinja': [
      {'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker (Wonder Guard)'},
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Attacker (Wonder Guard)'},
    ],
    // Weather form
    'castform': [
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Weather Special Attacker'},
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Weather Attacker'},
    ],
    // Illusion
    'zorua': [
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker (Illusion)'},
    ],
    'zoroark': [
      {'nature': 'Timid', 'reason': '+Speed / -Attack', 'role': 'Fast Special Attacker (Illusion)'},
      {'nature': 'Naive', 'reason': '+Speed / -Sp. Def', 'role': 'Mixed Attacker (Illusion)'},
    ],
    // Bulky Pokemon often run as walls despite offensive stat leans
    'slowbro': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physical Wall'},
      {'nature': 'Relaxed', 'reason': '+Defense / -Speed', 'role': 'Physical Wall (Trick Room)'},
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Bulky Special Attacker'},
    ],
    'slowking': [
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Special Wall'},
      {'nature': 'Sassy', 'reason': '+Sp. Def / -Speed', 'role': 'Special Wall (Trick Room)'},
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Bulky Special Attacker'},
    ],
    'cresselia': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physically Defensive Support'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive Support'},
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Bulky Attacker'},
    ],
    'ferrothorn': [
      {'nature': 'Relaxed', 'reason': '+Defense / -Speed', 'role': 'Physical Wall (Gyro Ball)'},
      {'nature': 'Sassy', 'reason': '+Sp. Def / -Speed', 'role': 'Specially Defensive (Gyro Ball)'},
      {'nature': 'Impish', 'reason': '+Defense / -Sp. Atk', 'role': 'Physical Wall'},
    ],
    'toxapex': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physical Wall'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Special Wall'},
    ],
    'clefable': [
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Physically Defensive (Magic Guard)'},
      {'nature': 'Calm', 'reason': '+Sp. Def / -Attack', 'role': 'Specially Defensive'},
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Offensive (Magic Guard / Unaware)'},
    ],
    // Gyro Ball / low speed users
    'torkoal': [
      {'nature': 'Quiet', 'reason': '+Sp. Atk / -Speed', 'role': 'Drought Trick Room Attacker'},
      {'nature': 'Bold', 'reason': '+Defense / -Attack', 'role': 'Defensive Drought Setter'},
    ],
    // Unique stat forms
    'palafin': [
      {'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Physical Attacker (Hero form)'},
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker (Hero form)'},
    ],
    'darmanitan': [
      {'nature': 'Jolly', 'reason': '+Speed / -Sp. Atk', 'role': 'Fast Physical Attacker'},
      {'nature': 'Adamant', 'reason': '+Attack / -Sp. Atk', 'role': 'Power Physical Attacker'},
    ],
    // Competitive support
    'dusclops': [
      {'nature': 'Relaxed', 'reason': '+Defense / -Speed', 'role': 'Eviolite Physical Wall (Trick Room)'},
      {'nature': 'Sassy', 'reason': '+Sp. Def / -Speed', 'role': 'Eviolite Special Wall (Trick Room)'},
    ],
    'porygon2': [
      {'nature': 'Relaxed', 'reason': '+Defense / -Speed', 'role': 'Eviolite Wall (Trick Room setter)'},
      {'nature': 'Sassy', 'reason': '+Sp. Def / -Speed', 'role': 'Eviolite Special Wall (Trick Room)'},
      {'nature': 'Modest', 'reason': '+Sp. Atk / -Attack', 'role': 'Bulky Attacker'},
    ],
  };
}
