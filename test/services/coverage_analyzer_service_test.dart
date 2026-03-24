import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/coverage_analyzer_service.dart';

void main() {
  group('CoverageAnalyzerService', () {
    test('analyzeDefensiveWeaknesses returns correct weaknesses for Fire', () {
      final result = CoverageAnalyzerService.analyzeDefensiveWeaknesses([['Fire']]);
      expect(result['Water'], 1);
      expect(result['Ground'], 1);
      expect(result['Rock'], 1);
    });

    test('analyzeDefensiveResistances returns correct resistances for Fire', () {
      final result = CoverageAnalyzerService.analyzeDefensiveResistances([['Fire']]);
      expect(result['Grass'], 1);
      expect(result['Bug'], 1);
      expect(result['Ice'], 1);
      expect(result['Steel'], 1);
    });

    test('analyzeOffensiveCoverage returns all 18 types', () {
      final result = CoverageAnalyzerService.analyzeOffensiveCoverage([['Fire', 'Water']]);
      expect(result.length, 18);
    });

    test('getUncoveredTypes identifies types not hit super effectively', () {
      final uncovered = CoverageAnalyzerService.getUncoveredTypes([['Normal']]);
      // Normal isn't super effective against anything
      expect(uncovered.length, 18);
    });

    test('getSharedWeaknesses identifies common weaknesses', () {
      final shared = CoverageAnalyzerService.getSharedWeaknesses([
        ['Fire'],
        ['Grass'],
      ]);
      expect(shared, isA<List<MapEntry<String, int>>>());
    });

    test('analyzeTeam returns complete analysis', () {
      final analysis = CoverageAnalyzerService.analyzeTeam(
        teamTypes: [['Fire'], ['Water'], ['Grass']],
        teamMoveTypes: [['Fire'], ['Water'], ['Grass']],
      );
      expect(analysis, contains('weaknesses'));
      expect(analysis, contains('offensiveCoverage'));
      expect(analysis, contains('uncoveredTypes'));
      expect(analysis, contains('sharedWeaknesses'));
    });
  });
}
