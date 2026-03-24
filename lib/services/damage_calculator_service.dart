import 'dart:math';
import 'type_effectiveness_service.dart' hide Color;

/// Service for calculating Pokemon battle damage
class DamageCalculatorService {
  /// Calculate damage using Gen V+ formula
  /// Returns {min, max, minPercent, maxPercent, hits} map
  static Map<String, dynamic> calculateDamage({
    required int level,
    required int attackStat,
    required int defenseStat,
    required int movePower,
    required String moveType,
    required String moveCategory, // 'physical' or 'special'
    required List<String> attackerTypes,
    required List<String> defenderTypes,
    required int defenderHP,
    bool isCritical = false,
    bool isSTAB = false,
    double weatherMod = 1.0,
    double screenMod = 1.0,
    double otherMod = 1.0,
    bool isBurned = false,
  }) {
    if (movePower == 0) {
      return {'min': 0, 'max': 0, 'minPercent': 0.0, 'maxPercent': 0.0, 'hits': 'No damage'};
    }

    // Base damage
    double baseDamage = ((2.0 * level / 5.0 + 2) * movePower * attackStat / defenseStat) / 50.0 + 2;

    // Critical hit (1.5x in Gen VI+)
    if (isCritical) baseDamage *= 1.5;

    // STAB
    double stabMod = 1.0;
    if (isSTAB || attackerTypes.contains(moveType)) {
      stabMod = 1.5;
    }

    // Type effectiveness
    double typeEffect = TypeEffectivenessService.getCombinedEffectiveness(moveType, defenderTypes);

    // Burn (halves physical damage)
    double burnMod = (isBurned && moveCategory == 'physical') ? 0.5 : 1.0;

    // Combined modifiers (excluding random)
    double modifier = stabMod * typeEffect * weatherMod * screenMod * burnMod * otherMod;

    // Min roll (0.85) and max roll (1.0)
    int minDamage = max(1, (baseDamage * 0.85 * modifier).floor());
    int maxDamage = max(1, (baseDamage * 1.0 * modifier).floor());

    if (typeEffect == 0) {
      minDamage = 0;
      maxDamage = 0;
    }

    double minPercent = defenderHP > 0 ? (minDamage / defenderHP) * 100 : 0;
    double maxPercent = defenderHP > 0 ? (maxDamage / defenderHP) * 100 : 0;

    // Calculate KO hits
    String hits;
    if (maxDamage == 0) {
      hits = 'No damage';
    } else if (minDamage >= defenderHP) {
      hits = 'Guaranteed OHKO';
    } else if (maxDamage >= defenderHP) {
      hits = 'Possible OHKO';
    } else if (minDamage * 2 >= defenderHP) {
      hits = 'Guaranteed 2HKO';
    } else if (maxDamage * 2 >= defenderHP) {
      hits = 'Possible 2HKO';
    } else if (minDamage * 3 >= defenderHP) {
      hits = 'Guaranteed 3HKO';
    } else if (maxDamage * 3 >= defenderHP) {
      hits = 'Possible 3HKO';
    } else {
      int minHits = (defenderHP / maxDamage).ceil();
      hits = '${minHits}HKO';
    }

    return {
      'min': minDamage,
      'max': maxDamage,
      'minPercent': minPercent,
      'maxPercent': maxPercent,
      'hits': hits,
      'typeEffect': typeEffect,
      'stab': stabMod > 1.0,
    };
  }

  /// Get effectiveness label
  static String getEffectivenessLabel(double multiplier) {
    if (multiplier == 0) return 'No effect';
    if (multiplier == 0.25) return 'Doubly resisted';
    if (multiplier == 0.5) return 'Not very effective';
    if (multiplier == 1.0) return 'Neutral';
    if (multiplier == 2.0) return 'Super effective';
    if (multiplier == 4.0) return 'Doubly super effective';
    return '${multiplier}x';
  }
}
