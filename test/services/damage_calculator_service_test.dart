import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/damage_calculator_service.dart';

void main() {
  group('DamageCalculatorService', () {
    test('calculates damage with neutral effectiveness', () {
      final result = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Normal',
        moveCategory: 'physical',
        attackerTypes: ['Normal'],
        defenderTypes: ['Fire'],
        defenderHP: 200,
      );

      expect(result['min'], greaterThan(0));
      expect(result['max'], greaterThanOrEqualTo(result['min']));
      expect(result['minPercent'], greaterThan(0));
    });

    test('STAB increases damage', () {
      final withoutStab = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Fire',
        moveCategory: 'physical',
        attackerTypes: ['Normal'],
        defenderTypes: ['Normal'],
        defenderHP: 200,
      );

      final withStab = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Fire',
        moveCategory: 'physical',
        attackerTypes: ['Fire'],
        defenderTypes: ['Normal'],
        defenderHP: 200,
      );

      expect(withStab['max'], greaterThan(withoutStab['max']));
    });

    test('critical hit increases damage', () {
      final normal = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Normal',
        moveCategory: 'physical',
        attackerTypes: ['Normal'],
        defenderTypes: ['Fire'],
        defenderHP: 200,
      );

      final crit = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Normal',
        moveCategory: 'physical',
        attackerTypes: ['Normal'],
        defenderTypes: ['Fire'],
        defenderHP: 200,
        isCritical: true,
      );

      expect(crit['max'], greaterThan(normal['max']));
    });

    test('super effective doubles damage', () {
      final neutral = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Fire',
        moveCategory: 'physical',
        attackerTypes: ['Fire'],
        defenderTypes: ['Normal'],
        defenderHP: 200,
      );

      final superEffective = DamageCalculatorService.calculateDamage(
        level: 50,
        attackStat: 100,
        defenseStat: 100,
        movePower: 80,
        moveType: 'Fire',
        moveCategory: 'physical',
        attackerTypes: ['Fire'],
        defenderTypes: ['Grass'],
        defenderHP: 200,
      );

      expect(superEffective['max'], greaterThan(neutral['max']));
    });

    test('getEffectivenessLabel returns correct labels', () {
      expect(DamageCalculatorService.getEffectivenessLabel(2.0), 'Super effective');
      expect(DamageCalculatorService.getEffectivenessLabel(0.5), 'Not very effective');
      expect(DamageCalculatorService.getEffectivenessLabel(0.0), 'No effect');
      expect(DamageCalculatorService.getEffectivenessLabel(1.0), 'Neutral');
    });
  });
}
