import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/experience_service.dart';

void main() {
  group('ExperienceService', () {
    group('totalXPForLevel', () {
      test('level 1 and below costs no XP', () {
        for (final rate in ExperienceService.allGrowthRates) {
          expect(ExperienceService.totalXPForLevel(rate, 1), 0, reason: rate);
          expect(ExperienceService.totalXPForLevel(rate, 0), 0, reason: rate);
          expect(ExperienceService.totalXPForLevel(rate, -5), 0, reason: rate);
        }
      });

      // The defining totals for each curve at level 100.
      test('matches the canonical level 100 total for every growth rate', () {
        const expected = {
          'erratic': 600000,
          'fast': 800000,
          'medium-fast': 1000000,
          'medium-slow': 1059860,
          'slow': 1250000,
          'fluctuating': 1640000,
        };
        expected.forEach((rate, total) {
          expect(ExperienceService.totalXPForLevel(rate, 100), total,
              reason: rate);
        });
      });

      test('matches known mid-curve reference points', () {
        // medium-fast is simply n^3.
        expect(ExperienceService.totalXPForLevel('medium-fast', 50), 125000);
        // erratic below level 50 uses n^3(100-n)/50.
        expect(ExperienceService.totalXPForLevel('erratic', 50), 125000);
        // fast is 4n^3/5.
        expect(ExperienceService.totalXPForLevel('fast', 50), 100000);
        // slow is 5n^3/4.
        expect(ExperienceService.totalXPForLevel('slow', 50), 156250);
      });

      test('levels above 100 are clamped to the level 100 total', () {
        for (final rate in ExperienceService.allGrowthRates) {
          expect(ExperienceService.totalXPForLevel(rate, 150),
              ExperienceService.totalXPForLevel(rate, 100),
              reason: rate);
        }
      });

      test('every curve increases monotonically from level 1 to 100', () {
        for (final rate in ExperienceService.allGrowthRates) {
          var previous = ExperienceService.totalXPForLevel(rate, 1);
          for (var level = 2; level <= 100; level++) {
            final current = ExperienceService.totalXPForLevel(rate, level);
            expect(current, greaterThan(previous),
                reason: '$rate went down at level $level');
            previous = current;
          }
        }
      });

      test('an unknown growth rate falls back to medium-fast', () {
        expect(ExperienceService.totalXPForLevel('not-a-rate', 50),
            ExperienceService.totalXPForLevel('medium-fast', 50));
      });

      test('curves rank as expected at level 100', () {
        int at(String r) => ExperienceService.totalXPForLevel(r, 100);
        expect(at('erratic'), lessThan(at('fast')));
        expect(at('fast'), lessThan(at('medium-fast')));
        expect(at('medium-fast'), lessThan(at('medium-slow')));
        expect(at('medium-slow'), lessThan(at('slow')));
        expect(at('slow'), lessThan(at('fluctuating')));
      });
    });

    group('xpBetweenLevels', () {
      test('is the difference of the two totals', () {
        expect(ExperienceService.xpBetweenLevels('medium-fast', 10, 20),
            20 * 20 * 20 - 10 * 10 * 10);
      });

      test('is zero across the same level', () {
        expect(ExperienceService.xpBetweenLevels('slow', 42, 42), 0);
      });

      test('is negative when the range runs backwards', () {
        expect(ExperienceService.xpBetweenLevels('fast', 50, 10), lessThan(0));
      });

      test('summing single level steps equals the whole span', () {
        for (final rate in ExperienceService.allGrowthRates) {
          var sum = 0;
          for (var level = 1; level < 100; level++) {
            sum += ExperienceService.xpBetweenLevels(rate, level, level + 1);
          }
          expect(sum, ExperienceService.totalXPForLevel(rate, 100),
              reason: rate);
        }
      });
    });

    group('getXPTable', () {
      test('covers the requested inclusive range', () {
        final table = ExperienceService.getXPTable('medium-fast',
            fromLevel: 5, toLevel: 10);
        expect(table, isNotEmpty);
        expect(table.first['level'], 5);
        expect(table.last['level'], 10);
      });

      test('defaults span levels 1 to 100', () {
        final table = ExperienceService.getXPTable('slow');
        expect(table.first['level'], 1);
        expect(table.last['level'], 100);
      });
    });

    test('every growth rate has a description', () {
      for (final rate in ExperienceService.allGrowthRates) {
        expect(ExperienceService.groupDescriptions[rate], isNotNull,
            reason: rate);
        expect(ExperienceService.groupDescriptions[rate], isNotEmpty,
            reason: rate);
      }
    });
  });
}
