import 'dart:math';

/// Service for calculating Pokemon catch rates
class CatchCalculatorService {
  /// Calculate catch probability
  /// Returns probability as a percentage (0-100)
  static Map<String, dynamic> calculateCatchRate({
    required int baseCatchRate,
    required double hpPercent,
    required String ballType,
    required String statusCondition,
    int level = 50,
    bool isNight = false,
    bool isInWater = false,
    bool isInCave = false,
    int turnCount = 1,
  }) {
    double ballBonus = _getBallModifier(ballType,
      isNight: isNight, isInWater: isInWater, isInCave: isInCave,
      turnCount: turnCount, level: level);
    double statusBonus = _getStatusModifier(statusCondition);

    // Gen V+ catch rate formula
    // a = ((3 * maxHP - 2 * currentHP) / (3 * maxHP)) * catchRate * ballBonus * statusBonus
    double hpFactor = (3.0 - 2.0 * hpPercent / 100.0) / 3.0;
    double a = hpFactor * baseCatchRate * ballBonus * statusBonus;

    // Clamp a to max 255
    a = a.clamp(0, 255);

    // Shake probability: b = 65536 / (255 / a)^(3/16)
    double catchProb;
    if (a >= 255) {
      catchProb = 100.0;
    } else {
      double b = 65536.0 / pow(255.0 / a, 3.0 / 16.0);
      // Probability of catching = (b/65536)^4
      catchProb = pow(b / 65536.0, 4).toDouble() * 100.0;
    }

    // Also calculate per-shake probability
    double shakeProb;
    if (a >= 255) {
      shakeProb = 100.0;
    } else {
      double b = 65536.0 / pow(255.0 / a, 3.0 / 16.0);
      shakeProb = (b / 65536.0) * 100.0;
    }

    return {
      'catchProbability': catchProb.clamp(0, 100),
      'shakeProbability': shakeProb.clamp(0, 100),
      'modifiedCatchRate': a,
      'ballModifier': ballBonus,
      'statusModifier': statusBonus,
      'averageAttempts': catchProb > 0 ? (100.0 / catchProb).ceil() : 999,
    };
  }

  static double _getBallModifier(String ball, {
    bool isNight = false, bool isInWater = false, bool isInCave = false,
    int turnCount = 1, int level = 50,
  }) {
    switch (ball) {
      case 'Poke Ball': return 1.0;
      case 'Great Ball': return 1.5;
      case 'Ultra Ball': return 2.0;
      case 'Master Ball': return 255.0;
      case 'Net Ball': return isInWater ? 3.5 : 1.0;
      case 'Dive Ball': return isInWater ? 3.5 : 1.0;
      case 'Nest Ball': return level < 30 ? max(1.0, (41 - level) / 10.0) : 1.0;
      case 'Repeat Ball': return 3.5; // Assumes already caught
      case 'Timer Ball': return min(4.0, 1.0 + turnCount * 1229 / 4096);
      case 'Luxury Ball': return 1.0;
      case 'Premier Ball': return 1.0;
      case 'Dusk Ball': return (isNight || isInCave) ? 3.0 : 1.0;
      case 'Heal Ball': return 1.0;
      case 'Quick Ball': return turnCount == 1 ? 5.0 : 1.0;
      case 'Level Ball':
        return 4.0; // Simplified
      case 'Lure Ball': return isInWater ? 4.0 : 1.0;
      case 'Moon Ball': return 4.0; // For Moon Stone evolutions
      case 'Heavy Ball': return 1.0; // Flat modifier, simplified
      case 'Love Ball': return 8.0; // Assumes opposite gender
      case 'Friend Ball': return 1.0;
      case 'Fast Ball': return 4.0; // For Pokemon with 100+ Speed
      case 'Dream Ball': return 4.0; // For sleeping Pokemon
      case 'Beast Ball': return 0.1; // Very low for non-UBs
      default: return 1.0;
    }
  }

  static double _getStatusModifier(String status) {
    switch (status) {
      case 'Sleep': return 2.5;
      case 'Freeze': return 2.5;
      case 'Paralysis': return 1.5;
      case 'Poison': return 1.5;
      case 'Burn': return 1.5;
      case 'None': default: return 1.0;
    }
  }

  static const List<String> allBalls = [
    'Poke Ball', 'Great Ball', 'Ultra Ball', 'Master Ball',
    'Net Ball', 'Dive Ball', 'Nest Ball', 'Repeat Ball',
    'Timer Ball', 'Luxury Ball', 'Premier Ball', 'Dusk Ball',
    'Heal Ball', 'Quick Ball', 'Level Ball', 'Lure Ball',
    'Moon Ball', 'Heavy Ball', 'Love Ball', 'Friend Ball',
    'Fast Ball', 'Dream Ball', 'Beast Ball',
  ];

  static const List<String> allStatuses = [
    'None', 'Sleep', 'Freeze', 'Paralysis', 'Poison', 'Burn',
  ];
}
