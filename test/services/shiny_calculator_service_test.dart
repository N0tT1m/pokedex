import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/shiny_calculator_service.dart';

void main() {
  group('ShinyCalculatorService', () {
    test('full odds match the generation base rate', () {
      // Gen 6+ is 1/4096, Gen 2-5 is 1/8192.
      final gen6 = ShinyCalculatorService.calculateOdds(
        method: 'Full Odds',
        generation: 6,
      );
      expect(gen6['effectiveOdds'], 4096);

      final gen5 = ShinyCalculatorService.calculateOdds(
        method: 'Full Odds',
        generation: 5,
      );
      expect(gen5['effectiveOdds'], 8192);
    });

    test('shiny charm adds two rolls to full odds', () {
      // Gen 6+ full odds with charm: 3 rolls out of 4096 => ~1/1365.
      final result = ShinyCalculatorService.calculateOdds(
        method: 'Full Odds',
        generation: 6,
        hasShinyCharm: true,
      );
      expect(result['effectiveOdds'], 1365); // round(4096 / 3)
    });

    group('Masuda Method (6 total rolls in Gen V+, 5 in Gen IV)', () {
      test('Gen VI without charm is 1/683', () {
        // 6 rolls out of 4096 => round(4096 / 6) = 683.
        final result = ShinyCalculatorService.calculateOdds(
          method: 'Masuda Method',
          generation: 6,
        );
        expect(result['effectiveOdds'], 683);
      });

      test('Gen VI with shiny charm is 1/512', () {
        // 8 rolls out of 4096 => round(4096 / 8) = 512.
        final result = ShinyCalculatorService.calculateOdds(
          method: 'Masuda Method',
          generation: 6,
          hasShinyCharm: true,
        );
        expect(result['effectiveOdds'], 512);
      });

      test('Gen IV without charm is 1/1638', () {
        // Gen IV: 5 rolls out of 8192 => round(8192 / 5) = 1638.
        final result = ShinyCalculatorService.calculateOdds(
          method: 'Masuda Method',
          generation: 4,
        );
        expect(result['effectiveOdds'], 1638);
      });
    });
  });
}
