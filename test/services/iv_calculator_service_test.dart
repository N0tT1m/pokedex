import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/iv_calculator_service.dart';

void main() {
  group('IVCalculatorService', () {
    test('HP formula calculates correctly', () {
      final stat = IVCalculatorService.calculateSingleStat(
        baseStat: 35,
        iv: 31,
        ev: 252,
        level: 50,
        natureModifier: 1.0,
        isHP: true,
      );
      expect(stat, greaterThan(100));
    });

    test('other stat formula with neutral nature', () {
      final stat = IVCalculatorService.calculateSingleStat(
        baseStat: 100,
        iv: 31,
        ev: 252,
        level: 50,
        natureModifier: 1.0,
        isHP: false,
      );
      expect(stat, greaterThan(0));
    });

    test('nature modifiers are correct', () {
      final mods = IVCalculatorService.getNatureModifiers('Adamant');
      expect(mods['Attack'], 1.1);
      expect(mods['Sp. Atk'], 0.9);
      expect(mods['HP'], 1.0);
    });

    test('hardy nature has all neutral modifiers', () {
      final mods = IVCalculatorService.getNatureModifiers('Hardy');
      for (var value in mods.values) {
        expect(value, 1.0);
      }
    });

    test('all 25 natures are defined', () {
      expect(IVCalculatorService.allNatures.length, 25);
    });

    test('boosted nature gives higher stat', () {
      final neutral = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 31, ev: 252, level: 50, natureModifier: 1.0, isHP: false,
      );
      final boosted = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 31, ev: 252, level: 50, natureModifier: 1.1, isHP: false,
      );
      expect(boosted, greaterThan(neutral));
    });

    test('IV range calculation returns valid range', () {
      // First calculate a stat value, then verify IV range finds it
      final stat = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 15, ev: 0, level: 50, natureModifier: 1.0, isHP: false,
      );
      final range = IVCalculatorService.calculateIVRange(
        baseStat: 100, observedStat: stat, ev: 0, level: 50, natureModifier: 1.0, isHP: false,
      );
      expect(range['min'], lessThanOrEqualTo(15));
      expect(range['max'], greaterThanOrEqualTo(15));
    });

    test('IV range reports an exact IV of 0 without falling back', () {
      // Regression: an IV of 0 used to be treated as "no match found" and the
      // result was silently downgraded to the approximate path.
      final stat = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 0, ev: 0, level: 50, natureModifier: 1.0, isHP: false,
      );
      final range = IVCalculatorService.calculateIVRange(
        baseStat: 100, observedStat: stat, ev: 0, level: 50, natureModifier: 1.0, isHP: false,
      );
      expect(range.containsKey('approximate'), isFalse);
      expect(range['min'], 0);
      expect(range['max'], greaterThanOrEqualTo(0));
    });

    test('HP formula matches known reference value (Charizard L100)', () {
      // Charizard base HP 78, 31 IV, 0 EV, L100 => 297 (Bulbapedia reference).
      final stat = IVCalculatorService.calculateSingleStat(
        baseStat: 78, iv: 31, ev: 0, level: 100, natureModifier: 1.0, isHP: true,
      );
      expect(stat, 297);
    });

    test('non-HP formula matches known reference value (Charizard Speed L100)', () {
      // Charizard base Speed 100, 31 IV, 0 EV, L100, neutral nature => 236.
      final stat = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 31, ev: 0, level: 100, natureModifier: 1.0, isHP: false,
      );
      expect(stat, 236);
    });

    test('EV contribution floors EV/4 exactly (1 point per 4 EVs)', () {
      // 4 EVs at L100 add exactly 1 to a stat; 3 EVs add 0 (floor).
      final base = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 31, ev: 0, level: 100, natureModifier: 1.0, isHP: false,
      );
      final withThree = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 31, ev: 3, level: 100, natureModifier: 1.0, isHP: false,
      );
      final withFour = IVCalculatorService.calculateSingleStat(
        baseStat: 100, iv: 31, ev: 4, level: 100, natureModifier: 1.0, isHP: false,
      );
      expect(withThree, base);
      expect(withFour, base + 1);
    });
  });
}
