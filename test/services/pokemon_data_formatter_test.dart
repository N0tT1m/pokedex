import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/services/pokemon_data_formatter.dart';

/// A minimal but realistic PokeAPI `/pokemon/{id}` payload.
Map<String, dynamic> pokemonPayload({
  int id = 6,
  String name = 'charizard',
  int height = 17,
  int weight = 905,
}) =>
    {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'base_experience': 267,
      'sprites': {
        'front_default': 'https://example.test/$id.png',
        'other': {
          'official-artwork': {
            'front_default': 'https://example.test/art/$id.png'
          }
        }
      },
      'types': [
        {
          'slot': 1,
          'type': {'name': 'fire'}
        },
        {
          'slot': 2,
          'type': {'name': 'flying'}
        },
      ],
      'abilities': [
        {
          'is_hidden': false,
          'ability': {'name': 'blaze'}
        },
        {
          'is_hidden': true,
          'ability': {'name': 'solar-power'}
        },
      ],
      'stats': [
        {
          'base_stat': 78,
          'effort': 0,
          'stat': {'name': 'hp'}
        },
        {
          'base_stat': 84,
          'effort': 0,
          'stat': {'name': 'attack'}
        },
        {
          'base_stat': 78,
          'effort': 0,
          'stat': {'name': 'defense'}
        },
        {
          'base_stat': 109,
          'effort': 3,
          'stat': {'name': 'special-attack'}
        },
        {
          'base_stat': 85,
          'effort': 0,
          'stat': {'name': 'special-defense'}
        },
        {
          'base_stat': 100,
          'effort': 0,
          'stat': {'name': 'speed'}
        },
      ],
    };

/// A minimal but realistic PokeAPI `/pokemon-species/{id}` payload.
Map<String, dynamic> speciesPayload({
  int? genderRate = 1,
  int? baseHappiness = 70,
  int captureRate = 45,
}) =>
    {
      'gender_rate': genderRate,
      'base_happiness': baseHappiness,
      'capture_rate': captureRate,
      'hatch_counter': 20,
      'growth_rate': {'name': 'medium-slow'},
      'egg_groups': [
        {'name': 'monster'},
        {'name': 'dragon'}
      ],
      'genera': [
        {
          'genus': 'Flame Pokémon',
          'language': {'name': 'en'}
        },
      ],
      'flavor_text_entries': [
        {
          'flavor_text': 'It spits fire.',
          'language': {'name': 'en'}
        },
      ],
    };

void main() {
  group('PokemonDataFormatter', () {
    group('capitalize', () {
      test('capitalises a simple name', () {
        expect(PokemonDataFormatter.capitalize('pikachu'), 'Pikachu');
      });

      test('turns hyphenated API names into spaced display names', () {
        expect(PokemonDataFormatter.capitalize('mr-mime'), 'Mr Mime');
        expect(PokemonDataFormatter.capitalize('ho-oh'), 'Ho Oh');
      });

      test('handles the empty string', () {
        expect(PokemonDataFormatter.capitalize(''), '');
      });
    });

    group('toApiFormat', () {
      test('turns a display name back into an API slug', () {
        expect(PokemonDataFormatter.toApiFormat('Mr Mime'), 'mr-mime');
        expect(PokemonDataFormatter.toApiFormat('Charizard'), 'charizard');
      });

      test('round-trips with capitalize', () {
        for (final slug in ['mr-mime', 'ho-oh', 'porygon-z', 'charizard']) {
          expect(
              PokemonDataFormatter.toApiFormat(
                  PokemonDataFormatter.capitalize(slug)),
              slug);
        }
      });

      test('handles the empty string', () {
        expect(PokemonDataFormatter.toApiFormat(''), '');
      });
    });

    group('formatPokemonData', () {
      test('formats core Pokedex fields', () async {
        final r = await PokemonDataFormatter.formatPokemonData(
            pokemonPayload(), speciesPayload(), null);
        final dex = r['data']['Pokédex Data'];

        expect(r['name'], 'Charizard');
        expect(r['id'], 6);
        expect(dex['National №'], '0006');
        expect(dex['Type'], contains('Fire'));
        expect(dex['Type'], contains('Flying'));
        expect(dex['Species'], 'Flame Pokémon');
      });

      test('converts height and weight to both unit systems', () async {
        final r = await PokemonDataFormatter.formatPokemonData(
            pokemonPayload(), speciesPayload(), null);
        final dex = r['data']['Pokédex Data'];
        // 17 decimetres = 1.7 m = 5'7"; 905 hectograms = 90.5 kg = 199.5 lbs.
        expect(dex['Height'], '1.7 m (5\'7")');
        expect(dex['Weight'], contains('90.5 kg'));
        expect(dex['Weight'], contains('199.5'));
      });

      // gender_rate is the count of eighths that are female:
      // 1 => 12.5% female, 87.5% male. -1 alone means genderless.
      group('gender rate', () {
        Future<String> genderFor(int? rate) async {
          final r = await PokemonDataFormatter.formatPokemonData(
              pokemonPayload(), speciesPayload(genderRate: rate), null);
          return r['data']['Breeding']['Gender'] as String;
        }

        test('-1 is genderless', () async {
          expect(await genderFor(-1), 'Genderless');
        });

        test('null is treated as genderless', () async {
          expect(await genderFor(null), 'Genderless');
        });

        test('0 is entirely male', () async {
          expect(await genderFor(0), '100.0% ♂, 0.0% ♀');
        });

        test('8 is entirely female', () async {
          expect(await genderFor(8), '0.0% ♂, 100.0% ♀');
        });

        test('1 is the standard 87.5/12.5 split', () async {
          expect(await genderFor(1), '87.5% ♂, 12.5% ♀');
        });

        test('4 is an even split', () async {
          expect(await genderFor(4), '50.0% ♂, 50.0% ♀');
        });

        test('a gendered species is never reported as genderless', () async {
          for (final rate in [0, 1, 2, 4, 6, 7, 8]) {
            expect(await genderFor(rate), isNot(contains('Genderless')),
                reason: 'gender_rate $rate');
          }
        });
      });

      test('reports EV yield from the stats block', () async {
        final r = await PokemonDataFormatter.formatPokemonData(
            pokemonPayload(), speciesPayload(), null);
        expect(r['data']['Training']['EV Yield'], contains('3'));
        expect(r['data']['Training']['EV Yield'], contains('Sp. Atk'));
      });

      test('carries through catch rate and growth rate', () async {
        final r = await PokemonDataFormatter.formatPokemonData(
            pokemonPayload(), speciesPayload(), null);
        final training = r['data']['Training'];
        expect(training['Catch Rate'].toString(), contains('45'));
        expect(training['Growth Rate'].toString().toLowerCase(),
            contains('medium'));
      });

      test('exposes all six base stats', () async {
        final r = await PokemonDataFormatter.formatPokemonData(
            pokemonPayload(), speciesPayload(), null);
        final stats = r['data']['Base Stats'] as Map;
        expect(stats.length, 6);
        expect(
            stats.values.map((v) => v.toString()).join(' '), contains('109'));
      });

      test('prefers official artwork over the default sprite', () async {
        final r = await PokemonDataFormatter.formatPokemonData(
            pokemonPayload(), speciesPayload(), null);
        expect(r['image'], contains('/art/'));
      });

      test('falls back to the default sprite when artwork is absent', () async {
        final p = pokemonPayload();
        p['sprites'] = {'front_default': 'https://example.test/6.png'};
        final r = await PokemonDataFormatter.formatPokemonData(
            p, speciesPayload(), null);
        expect(r['image'], 'https://example.test/6.png');
      });

      test('survives a species payload with missing optional fields', () async {
        final r = await PokemonDataFormatter.formatPokemonData(pokemonPayload(),
            speciesPayload(genderRate: null, baseHappiness: null), null);
        expect(r['name'], 'Charizard');
        expect(r['data']['Training'], isNotNull);
      });
    });
  });
}
