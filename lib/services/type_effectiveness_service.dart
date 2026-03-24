/// Service for Pokemon type effectiveness calculations
class TypeEffectivenessService {
  static const List<String> allTypes = [
    'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice',
    'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
    'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy',
  ];

  /// Full 18x18 type effectiveness chart
  /// _chart[attackingType][defendingType] = multiplier
  static final Map<String, Map<String, double>> _chart = _buildChart();

  static Map<String, Map<String, double>> _buildChart() {
    final chart = <String, Map<String, double>>{};
    for (var t in allTypes) {
      chart[t] = {for (var d in allTypes) d: 1.0};
    }

    void set(String atk, String def, double val) {
      chart[atk]![def] = val;
    }

    // Normal
    set('Normal', 'Rock', 0.5); set('Normal', 'Ghost', 0); set('Normal', 'Steel', 0.5);
    // Fire
    set('Fire', 'Fire', 0.5); set('Fire', 'Water', 0.5); set('Fire', 'Grass', 2); set('Fire', 'Ice', 2);
    set('Fire', 'Bug', 2); set('Fire', 'Rock', 0.5); set('Fire', 'Dragon', 0.5); set('Fire', 'Steel', 2);
    // Water
    set('Water', 'Fire', 2); set('Water', 'Water', 0.5); set('Water', 'Grass', 0.5); set('Water', 'Ground', 2);
    set('Water', 'Rock', 2); set('Water', 'Dragon', 0.5);
    // Electric
    set('Electric', 'Water', 2); set('Electric', 'Electric', 0.5); set('Electric', 'Grass', 0.5);
    set('Electric', 'Ground', 0); set('Electric', 'Flying', 2); set('Electric', 'Dragon', 0.5);
    // Grass
    set('Grass', 'Fire', 0.5); set('Grass', 'Water', 2); set('Grass', 'Grass', 0.5); set('Grass', 'Poison', 0.5);
    set('Grass', 'Ground', 2); set('Grass', 'Flying', 0.5); set('Grass', 'Bug', 0.5); set('Grass', 'Rock', 2);
    set('Grass', 'Dragon', 0.5); set('Grass', 'Steel', 0.5);
    // Ice
    set('Ice', 'Fire', 0.5); set('Ice', 'Water', 0.5); set('Ice', 'Grass', 2); set('Ice', 'Ice', 0.5);
    set('Ice', 'Ground', 2); set('Ice', 'Flying', 2); set('Ice', 'Dragon', 2); set('Ice', 'Steel', 0.5);
    // Fighting
    set('Fighting', 'Normal', 2); set('Fighting', 'Ice', 2); set('Fighting', 'Poison', 0.5);
    set('Fighting', 'Flying', 0.5); set('Fighting', 'Psychic', 0.5); set('Fighting', 'Bug', 0.5);
    set('Fighting', 'Rock', 2); set('Fighting', 'Ghost', 0); set('Fighting', 'Dark', 2);
    set('Fighting', 'Steel', 2); set('Fighting', 'Fairy', 0.5);
    // Poison
    set('Poison', 'Poison', 0.5); set('Poison', 'Ground', 0.5); set('Poison', 'Rock', 0.5);
    set('Poison', 'Ghost', 0.5); set('Poison', 'Steel', 0); set('Poison', 'Grass', 2); set('Poison', 'Fairy', 2);
    // Ground
    set('Ground', 'Fire', 2); set('Ground', 'Electric', 2); set('Ground', 'Grass', 0.5);
    set('Ground', 'Poison', 2); set('Ground', 'Flying', 0); set('Ground', 'Bug', 0.5);
    set('Ground', 'Rock', 2); set('Ground', 'Steel', 2);
    // Flying
    set('Flying', 'Electric', 0.5); set('Flying', 'Grass', 2); set('Flying', 'Fighting', 2);
    set('Flying', 'Bug', 2); set('Flying', 'Rock', 0.5); set('Flying', 'Steel', 0.5);
    // Psychic
    set('Psychic', 'Fighting', 2); set('Psychic', 'Poison', 2); set('Psychic', 'Psychic', 0.5);
    set('Psychic', 'Dark', 0); set('Psychic', 'Steel', 0.5);
    // Bug
    set('Bug', 'Fire', 0.5); set('Bug', 'Grass', 2); set('Bug', 'Fighting', 0.5);
    set('Bug', 'Poison', 0.5); set('Bug', 'Flying', 0.5); set('Bug', 'Psychic', 2);
    set('Bug', 'Ghost', 0.5); set('Bug', 'Dark', 2); set('Bug', 'Steel', 0.5); set('Bug', 'Fairy', 0.5);
    // Rock
    set('Rock', 'Fire', 2); set('Rock', 'Ice', 2); set('Rock', 'Fighting', 0.5);
    set('Rock', 'Ground', 0.5); set('Rock', 'Flying', 2); set('Rock', 'Bug', 2); set('Rock', 'Steel', 0.5);
    // Ghost
    set('Ghost', 'Normal', 0); set('Ghost', 'Psychic', 2); set('Ghost', 'Ghost', 2); set('Ghost', 'Dark', 0.5);
    // Dragon
    set('Dragon', 'Dragon', 2); set('Dragon', 'Steel', 0.5); set('Dragon', 'Fairy', 0);
    // Dark
    set('Dark', 'Fighting', 0.5); set('Dark', 'Psychic', 2); set('Dark', 'Ghost', 2);
    set('Dark', 'Dark', 0.5); set('Dark', 'Fairy', 0.5);
    // Steel
    set('Steel', 'Fire', 0.5); set('Steel', 'Water', 0.5); set('Steel', 'Electric', 0.5);
    set('Steel', 'Ice', 2); set('Steel', 'Rock', 2); set('Steel', 'Steel', 0.5); set('Steel', 'Fairy', 2);
    // Fairy
    set('Fairy', 'Fire', 0.5); set('Fairy', 'Poison', 0.5); set('Fairy', 'Fighting', 2);
    set('Fairy', 'Dragon', 2); set('Fairy', 'Dark', 2); set('Fairy', 'Steel', 0.5);

    return chart;
  }

  /// Get effectiveness of attackingType vs defendingType
  static double getEffectiveness(String attackingType, String defendingType) {
    return _chart[attackingType]?[defendingType] ?? 1.0;
  }

  /// Get combined effectiveness vs dual-type Pokemon
  static double getCombinedEffectiveness(String attackingType, List<String> defendingTypes) {
    double mult = 1.0;
    for (var t in defendingTypes) {
      mult *= getEffectiveness(attackingType, t);
    }
    return mult;
  }

  /// Get all weaknesses for a type combination
  static Map<String, double> getDefensiveMatchups(List<String> types) {
    final matchups = <String, double>{};
    for (var atkType in allTypes) {
      matchups[atkType] = getCombinedEffectiveness(atkType, types);
    }
    return matchups;
  }

  /// Get types this attacking type is super effective against
  static List<String> getSuperEffectiveAgainst(String attackingType) {
    return allTypes.where((t) => getEffectiveness(attackingType, t) > 1.0).toList();
  }

  /// Get types this attacking type is not very effective against
  static List<String> getNotVeryEffectiveAgainst(String attackingType) {
    return allTypes.where((t) {
      final e = getEffectiveness(attackingType, t);
      return e > 0 && e < 1.0;
    }).toList();
  }

  /// Get types this attacking type has no effect on
  static List<String> getNoEffectAgainst(String attackingType) {
    return allTypes.where((t) => getEffectiveness(attackingType, t) == 0).toList();
  }

  /// Get the full chart for display
  static Map<String, Map<String, double>> get chart => _chart;
}
