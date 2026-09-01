import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/catch_calculator_service.dart';

/// Convenience wrapper so each test reads as the scenario it describes.
Map<String, dynamic> calc({
  int baseCatchRate = 45,
  double hpPercent = 100,
  String ball = 'Poke Ball',
  String status = 'None',
  int level = 50,
  bool isNight = false,
  bool isInWater = false,
  bool isInCave = false,
  int turnCount = 1,
}) =>
    CatchCalculatorService.calculateCatchRate(
      baseCatchRate: baseCatchRate,
      hpPercent: hpPercent,
      ballType: ball,
      statusCondition: status,
      level: level,
      isNight: isNight,
      isInWater: isInWater,
      isInCave: isInCave,
      turnCount: turnCount,
    );

void main() {
  group('CatchCalculatorService', () {
    group('modified catch rate (a)', () {
      test('at full HP the HP factor is 1/3', () {
        // a = ((3 - 2*1.0)/3) * 45 * 1 * 1 = 15
        expect(calc()['modifiedCatchRate'], closeTo(15.0, 0.001));
      });

      test('at 1% HP the HP factor approaches 1', () {
        // Lower HP must never reduce the catch rate.
        final full = calc()['modifiedCatchRate'] as double;
        final low = calc(hpPercent: 1)['modifiedCatchRate'] as double;
        expect(low, greaterThan(full));
        expect(low, closeTo((3.0 - 0.02) / 3.0 * 45, 0.001));
      });

      test('is clamped to 255 so a Master Ball cannot overflow it', () {
        expect(calc(ball: 'Master Ball')['modifiedCatchRate'], 255.0);
      });

      test('scales linearly with the species base catch rate', () {
        final low = calc(baseCatchRate: 45)['modifiedCatchRate'] as double;
        final high = calc(baseCatchRate: 90)['modifiedCatchRate'] as double;
        expect(high, closeTo(low * 2, 0.001));
      });
    });

    group('probabilities', () {
      test('a Master Ball is a guaranteed catch', () {
        final r = calc(ball: 'Master Ball');
        expect(r['catchProbability'], 100.0);
        expect(r['shakeProbability'], 100.0);
        expect(r['averageAttempts'], 1);
      });

      test('probability stays within 0-100', () {
        for (final ball in CatchCalculatorService.allBalls) {
          for (final status in CatchCalculatorService.allStatuses) {
            final p = calc(
                ball: ball,
                status: status,
                hpPercent: 1)['catchProbability'] as double;
            expect(p, inInclusiveRange(0.0, 100.0),
                reason: '$ball / $status produced $p');
          }
        }
      });

      test('better balls never lower the catch chance', () {
        final poke = calc(ball: 'Poke Ball')['catchProbability'] as double;
        final great = calc(ball: 'Great Ball')['catchProbability'] as double;
        final ultra = calc(ball: 'Ultra Ball')['catchProbability'] as double;
        expect(great, greaterThan(poke));
        expect(ultra, greaterThan(great));
      });

      test('lower HP raises the catch chance', () {
        expect(calc(hpPercent: 5)['catchProbability'] as double,
            greaterThan(calc(hpPercent: 100)['catchProbability'] as double));
      });

      test('averageAttempts is the reciprocal of the catch chance', () {
        final r = calc(baseCatchRate: 255, hpPercent: 1);
        final p = r['catchProbability'] as double;
        expect(r['averageAttempts'], (100.0 / p).ceil());
      });
    });

    group('status modifiers', () {
      test('sleep and freeze give 2.5x', () {
        expect(calc(status: 'Sleep')['statusModifier'], 2.5);
        expect(calc(status: 'Freeze')['statusModifier'], 2.5);
      });

      test('paralysis, poison and burn give 1.5x', () {
        for (final s in ['Paralysis', 'Poison', 'Burn']) {
          expect(calc(status: s)['statusModifier'], 1.5, reason: s);
        }
      });

      test('no status gives 1x', () {
        expect(calc(status: 'None')['statusModifier'], 1.0);
      });
    });

    group('situational ball modifiers', () {
      test('Net and Dive Balls only apply in water', () {
        for (final b in ['Net Ball', 'Dive Ball']) {
          expect(calc(ball: b, isInWater: true)['ballModifier'], 3.5,
              reason: '$b in water');
          expect(calc(ball: b, isInWater: false)['ballModifier'], 1.0,
              reason: '$b on land');
        }
      });

      test('Dusk Ball applies at night or in a cave', () {
        expect(calc(ball: 'Dusk Ball', isNight: true)['ballModifier'], 3.0);
        expect(calc(ball: 'Dusk Ball', isInCave: true)['ballModifier'], 3.0);
        expect(calc(ball: 'Dusk Ball')['ballModifier'], 1.0);
      });

      test('Quick Ball only applies on the first turn', () {
        expect(calc(ball: 'Quick Ball', turnCount: 1)['ballModifier'], 5.0);
        expect(calc(ball: 'Quick Ball', turnCount: 2)['ballModifier'], 1.0);
      });

      test('Timer Ball grows with elapsed turns and caps at 4x', () {
        // Turn 1 means no turns have elapsed yet, so no bonus.
        expect(calc(ball: 'Timer Ball', turnCount: 1)['ballModifier'], 1.0);
        expect(calc(ball: 'Timer Ball', turnCount: 2)['ballModifier'],
            closeTo(1.0 + 1229 / 4096, 0.0001));
        expect(calc(ball: 'Timer Ball', turnCount: 100)['ballModifier'], 4.0);
      });

      test('Nest Ball favours low levels and floors at 1x', () {
        expect(calc(ball: 'Nest Ball', level: 1)['ballModifier'],
            closeTo(4.0, 0.0001));
        expect(calc(ball: 'Nest Ball', level: 30)['ballModifier'],
            closeTo(1.1, 0.0001));
        expect(calc(ball: 'Nest Ball', level: 31)['ballModifier'], 1.0);
        expect(calc(ball: 'Nest Ball', level: 70)['ballModifier'], 1.0);
      });

      test('an unknown ball falls back to 1x rather than throwing', () {
        expect(calc(ball: 'Not A Real Ball')['ballModifier'], 1.0);
      });
    });

    test('every listed ball and status is handled', () {
      for (final ball in CatchCalculatorService.allBalls) {
        expect(calc(ball: ball)['ballModifier'], isA<double>(), reason: ball);
      }
      for (final status in CatchCalculatorService.allStatuses) {
        expect(calc(status: status)['statusModifier'], isA<double>(),
            reason: status);
      }
    });
  });
}
