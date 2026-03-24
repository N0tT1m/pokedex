import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/type_effectiveness_service.dart';

void main() {
  group('TypeEffectivenessService', () {
    test('Fire is super effective against Grass', () {
      final result = TypeEffectivenessService.getEffectiveness('Fire', 'Grass');
      expect(result, 2.0);
    });

    test('Water is not very effective against Grass', () {
      final result = TypeEffectivenessService.getEffectiveness('Water', 'Grass');
      expect(result, 0.5);
    });

    test('Normal has no effect on Ghost', () {
      final result = TypeEffectivenessService.getEffectiveness('Normal', 'Ghost');
      expect(result, 0.0);
    });

    test('Electric has no effect on Ground', () {
      final result = TypeEffectivenessService.getEffectiveness('Electric', 'Ground');
      expect(result, 0.0);
    });

    test('combined effectiveness for dual type', () {
      // Fire vs Grass/Ice = 2.0 * 2.0 = 4.0
      final result = TypeEffectivenessService.getCombinedEffectiveness('Fire', ['Grass', 'Ice']);
      expect(result, 4.0);
    });

    test('combined effectiveness with resistance', () {
      // Fire vs Water/Rock = 0.5 * 0.5 = 0.25
      final result = TypeEffectivenessService.getCombinedEffectiveness('Fire', ['Water', 'Rock']);
      expect(result, 0.25);
    });

    test('getDefensiveMatchups returns all 18 types', () {
      final matchups = TypeEffectivenessService.getDefensiveMatchups(['Fire']);
      expect(matchups.length, 18);
    });

    test('getSuperEffectiveAgainst returns correct types', () {
      final types = TypeEffectivenessService.getSuperEffectiveAgainst('Fire');
      expect(types, contains('Grass'));
      expect(types, contains('Bug'));
      expect(types, contains('Ice'));
      expect(types, contains('Steel'));
    });

    test('getNoEffectAgainst returns correct types', () {
      final types = TypeEffectivenessService.getNoEffectAgainst('Normal');
      expect(types, contains('Ghost'));
    });

    test('same type effectiveness is neutral', () {
      final result = TypeEffectivenessService.getEffectiveness('Fire', 'Fire');
      expect(result, 0.5);
    });
  });
}
