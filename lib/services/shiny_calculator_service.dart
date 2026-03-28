import 'dart:math';

/// Service for calculating shiny encounter odds
class ShinyCalculatorService {
  static const int _fullOdds = 8192; // Gen 2-5
  static const int _fullOddsGen6 = 4096; // Gen 6+

  /// Calculate shiny odds for a given method
  static Map<String, dynamic> calculateOdds({
    required String method,
    required int generation,
    int chainLength = 0,
    bool hasShinyCharm = false,
    int dexNavSearchLevel = 0,
    int koCount = 0,
    int sandwichPower = 0,
  }) {
    int baseOdds = generation >= 6 ? _fullOddsGen6 : _fullOdds;
    int extraRolls = hasShinyCharm ? 2 : 0;
    double probability;

    switch (method) {
      case 'Full Odds':
        probability = 1.0 / (baseOdds / (1 + extraRolls));
        break;

      case 'Masuda Method':
        int masudaRolls = generation >= 5 ? 6 : 5;
        probability = 1.0 / (baseOdds / (1 + masudaRolls + extraRolls));
        break;

      case 'Chain Fishing':
        int fishRolls = min(chainLength, 20) * 2;
        probability = 1.0 / (baseOdds / (1 + fishRolls + extraRolls));
        break;

      case 'PokeRadar':
        int radarRolls;
        if (chainLength >= 40) {
          radarRolls = generation >= 8 ? 39 : 40;
        } else {
          radarRolls = chainLength;
        }
        probability = 1.0 / max(1, (baseOdds / (1 + radarRolls + extraRolls)));
        break;

      case 'SOS Chaining':
        int sosRolls;
        if (chainLength >= 31) sosRolls = 13;
        else if (chainLength >= 21) sosRolls = 9;
        else if (chainLength >= 11) sosRolls = 5;
        else sosRolls = 1;
        probability = 1.0 / (baseOdds / (sosRolls + extraRolls));
        break;

      case 'DexNav':
        int navRolls = min(dexNavSearchLevel ~/ 100, 5);
        probability = 1.0 / (baseOdds / (1 + navRolls + extraRolls));
        break;

      case 'Dynamax Adventures':
        probability = 1.0 / (300 / (1 + extraRolls));
        break;

      case 'Mass Outbreaks (PLA)':
        int outbreakRolls = 25 + extraRolls;
        probability = 1.0 / (baseOdds / outbreakRolls);
        break;

      case 'Massive Mass Outbreaks (PLA)':
        int mmRolls = 12 + extraRolls;
        probability = 1.0 / (baseOdds / mmRolls);
        break;

      case 'Sandwich Power (SV)':
        int svRolls = extraRolls;
        if (sandwichPower >= 3) svRolls += 3;
        else if (sandwichPower >= 2) svRolls += 2;
        else if (sandwichPower >= 1) svRolls += 1;
        probability = 1.0 / (baseOdds / (1 + svRolls));
        break;

      case 'KO Method (Sw/Sh)':
        int koRolls;
        if (koCount >= 500) koRolls = 6;
        else if (koCount >= 300) koRolls = 5;
        else if (koCount >= 200) koRolls = 4;
        else if (koCount >= 100) koRolls = 3;
        else if (koCount >= 50) koRolls = 2;
        else koRolls = 0;
        // Sword/Shield KO method has a 3% chance of activating the bonus
        probability = (0.03 * (1.0 / (baseOdds / (1 + koRolls + extraRolls)))) +
                      (0.97 * (1.0 / (baseOdds / (1 + extraRolls))));
        break;

      case 'Friend Safari':
        probability = 1.0 / (baseOdds / (1 + 5 + extraRolls));
        break;

      case 'Catch Combo (LGPE)':
        int comboRolls;
        if (chainLength >= 31) comboRolls = 11;
        else if (chainLength >= 21) comboRolls = 7;
        else if (chainLength >= 11) comboRolls = 3;
        else comboRolls = 0;
        probability = 1.0 / (baseOdds / (1 + comboRolls + extraRolls));
        break;

      default:
        probability = 1.0 / baseOdds;
    }

    probability = probability.clamp(0, 1);
    int effectiveOdds = (1.0 / probability).round();

    return {
      'probability': probability * 100,
      'odds': '1/$effectiveOdds',
      'effectiveOdds': effectiveOdds,
      'encountersFor50': _encountersForPercent(probability, 0.50),
      'encountersFor90': _encountersForPercent(probability, 0.90),
      'encountersFor99': _encountersForPercent(probability, 0.99),
    };
  }

  static int _encountersForPercent(double probability, double targetPercent) {
    if (probability >= 1) return 1;
    if (probability <= 0) return 999999;
    return (log(1 - targetPercent) / log(1 - probability)).ceil();
  }

  static const List<String> allMethods = [
    'Full Odds',
    'Masuda Method',
    'Chain Fishing',
    'PokeRadar',
    'SOS Chaining',
    'DexNav',
    'Dynamax Adventures',
    'Mass Outbreaks (PLA)',
    'Massive Mass Outbreaks (PLA)',
    'Sandwich Power (SV)',
    'KO Method (Sw/Sh)',
    'Friend Safari',
    'Catch Combo (LGPE)',
  ];

  static const Map<String, List<String>> methodsByGame = {
    'Red/Blue/Yellow': ['Full Odds'],
    'Gold/Silver/Crystal': ['Full Odds'],
    'Ruby/Sapphire/Emerald': ['Full Odds'],
    'FireRed/LeafGreen': ['Full Odds'],
    'Diamond/Pearl/Platinum': ['Full Odds', 'Masuda Method', 'PokeRadar'],
    'HeartGold/SoulSilver': ['Full Odds', 'Masuda Method'],
    'Black/White': ['Full Odds', 'Masuda Method'],
    'Black 2/White 2': ['Full Odds', 'Masuda Method'],
    'X/Y': ['Full Odds', 'Masuda Method', 'Chain Fishing', 'PokeRadar', 'Friend Safari'],
    'Omega Ruby/Alpha Sapphire': ['Full Odds', 'Masuda Method', 'Chain Fishing', 'DexNav'],
    'Sun/Moon': ['Full Odds', 'Masuda Method', 'SOS Chaining'],
    'Ultra Sun/Ultra Moon': ['Full Odds', 'Masuda Method', 'SOS Chaining'],
    'Let\'s Go Pikachu/Eevee': ['Full Odds', 'Catch Combo (LGPE)'],
    'Sword/Shield': ['Full Odds', 'Masuda Method', 'KO Method (Sw/Sh)', 'Dynamax Adventures'],
    'Brilliant Diamond/Shining Pearl': ['Full Odds', 'Masuda Method', 'PokeRadar'],
    'Legends: Arceus': ['Full Odds', 'Mass Outbreaks (PLA)', 'Massive Mass Outbreaks (PLA)'],
    'Scarlet/Violet': ['Full Odds', 'Masuda Method', 'Sandwich Power (SV)'],
  };
}
