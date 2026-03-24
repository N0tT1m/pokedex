import 'type_effectiveness_service.dart' hide Color;

/// Service for analyzing type coverage of a Pokemon team
class CoverageAnalyzerService {
  /// Analyze defensive weaknesses for a team
  /// Returns map of attacking type -> number of team members weak to it
  static Map<String, int> analyzeDefensiveWeaknesses(List<List<String>> teamTypes) {
    final weaknesses = <String, int>{};
    for (var atkType in TypeEffectivenessService.allTypes) {
      int weakCount = 0;
      for (var memberTypes in teamTypes) {
        double eff = TypeEffectivenessService.getCombinedEffectiveness(atkType, memberTypes);
        if (eff > 1.0) weakCount++;
      }
      if (weakCount > 0) weaknesses[atkType] = weakCount;
    }
    return weaknesses;
  }

  /// Analyze defensive resistances for a team
  static Map<String, int> analyzeDefensiveResistances(List<List<String>> teamTypes) {
    final resistances = <String, int>{};
    for (var atkType in TypeEffectivenessService.allTypes) {
      int resistCount = 0;
      for (var memberTypes in teamTypes) {
        double eff = TypeEffectivenessService.getCombinedEffectiveness(atkType, memberTypes);
        if (eff < 1.0) resistCount++;
      }
      if (resistCount > 0) resistances[atkType] = resistCount;
    }
    return resistances;
  }

  /// Analyze offensive coverage
  /// Given a list of move types per team member, find which types can be hit super effectively
  static Map<String, bool> analyzeOffensiveCoverage(List<List<String>> teamMoveTypes) {
    final coverage = <String, bool>{};
    for (var defType in TypeEffectivenessService.allTypes) {
      bool canHitSuperEffective = false;
      for (var memberMoves in teamMoveTypes) {
        for (var moveType in memberMoves) {
          if (TypeEffectivenessService.getEffectiveness(moveType, defType) > 1.0) {
            canHitSuperEffective = true;
            break;
          }
        }
        if (canHitSuperEffective) break;
      }
      coverage[defType] = canHitSuperEffective;
    }
    return coverage;
  }

  /// Get uncovered types (types the team can't hit super effectively)
  static List<String> getUncoveredTypes(List<List<String>> teamMoveTypes) {
    final coverage = analyzeOffensiveCoverage(teamMoveTypes);
    return coverage.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();
  }

  /// Get shared weaknesses (types multiple team members are weak to)
  static List<MapEntry<String, int>> getSharedWeaknesses(List<List<String>> teamTypes) {
    final weaknesses = analyzeDefensiveWeaknesses(teamTypes);
    final shared = weaknesses.entries.where((e) => e.value >= 2).toList();
    shared.sort((a, b) => b.value.compareTo(a.value));
    return shared;
  }

  /// Get a team analysis summary
  static Map<String, dynamic> analyzeTeam({
    required List<List<String>> teamTypes,
    required List<List<String>> teamMoveTypes,
  }) {
    return {
      'weaknesses': analyzeDefensiveWeaknesses(teamTypes),
      'resistances': analyzeDefensiveResistances(teamTypes),
      'offensiveCoverage': analyzeOffensiveCoverage(teamMoveTypes),
      'uncoveredTypes': getUncoveredTypes(teamMoveTypes),
      'sharedWeaknesses': getSharedWeaknesses(teamTypes),
    };
  }
}
