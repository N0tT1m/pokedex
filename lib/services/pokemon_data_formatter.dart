import 'pokeapi_service.dart';

/// Helper class to format and transform PokeAPI data into app-friendly structures
class PokemonDataFormatter {
  /// Formats Pokemon data from PokeAPI into the structure expected by Search.dart
  static Future<Map<String, dynamic>> formatPokemonData(
    Map<String, dynamic> pokemonData,
    Map<String, dynamic> speciesData,
    Map<String, dynamic>? evolutionData,
  ) async {
    // Extract basic info
    final id = pokemonData['id'];
    final name = capitalize(pokemonData['name']);
    final height = pokemonData['height']; // in decimeters
    final weight = pokemonData['weight']; // in hectograms

    // Get sprites
    final sprites = pokemonData['sprites'];
    final imageUrl = sprites['other']?['official-artwork']?['front_default'] ??
        sprites['front_default'] ??
        '';

    // Format types
    final types = (pokemonData['types'] as List)
        .map((t) => capitalize(t['type']['name']))
        .join(', ');

    // Format abilities
    final abilities = (pokemonData['abilities'] as List)
        .map((a) {
          final abilityName = capitalize(a['ability']['name'].replaceAll('-', ' '));
          final isHidden = a['is_hidden'] == true ? ' (Hidden)' : '';
          return '$abilityName$isHidden';
        })
        .join(', ');

    // Format stats
    final stats = <String, dynamic>{};
    for (var stat in pokemonData['stats']) {
      final statName = _formatStatName(stat['stat']['name']);
      stats[statName] = stat['base_stat'].toString();
    }

    // Extract species data
    final genera = _getEnglishValue(speciesData['genera'], 'genus') ?? 'Unknown Species';
    final captureRate = speciesData['capture_rate']?.toString() ?? 'N/A';
    final baseFriendship = speciesData['base_happiness']?.toString() ?? 'N/A';
    final growthRate = capitalize(speciesData['growth_rate']?['name']?.replaceAll('-', ' ') ?? 'N/A');
    final genderRate = _formatGenderRate(speciesData['gender_rate']);

    // Format egg groups
    final eggGroups = (speciesData['egg_groups'] as List?)
        ?.map((eg) => capitalize(eg['name'].replaceAll('-', ' ')))
        .join(', ') ?? 'N/A';

    // Calculate EV yield
    final evYield = _formatEvYield(pokemonData['stats']);

    // Get flavor text (Pokedex entry)
    final flavorText = _getEnglishFlavorText(speciesData['flavor_text_entries']);

    // Format evolution chain
    final evolutionChain = evolutionData != null
        ? _formatEvolutionChain(evolutionData['chain'])
        : [];

    // Build the data structure
    return {
      'image': imageUrl,
      'name': name,
      'id': id,
      'flavorText': flavorText,
      'titles': ['Pokédex Data', 'Training', 'Breeding', 'Base Stats', 'Evolution'],
      'data': {
        'Pokédex Data': {
          'National №': id.toString().padLeft(4, '0'),
          'Type': types,
          'Species': genera,
          'Height': '${(height / 10).toStringAsFixed(1)} m (${_metersToFeet(height / 10)})',
          'Weight': '${(weight / 10).toStringAsFixed(1)} kg (${_kgToLbs(weight / 10)} lbs)',
          'Abilities': abilities,
        },
        'Training': {
          'EV Yield': evYield,
          'Catch Rate': captureRate,
          'Base Friendship': baseFriendship,
          'Base Exp': pokemonData['base_experience']?.toString() ?? 'N/A',
          'Growth Rate': growthRate,
        },
        'Breeding': {
          'Egg Groups': eggGroups,
          'Gender': genderRate,
          'Egg Cycles': speciesData['hatch_counter']?.toString() ?? 'N/A',
        },
        'Base Stats': stats,
      },
      'evolution': evolutionChain,
      'locations': [], // Will be populated separately if needed
    };
  }

  /// Formats evolution chain recursively
  static List<Map<String, dynamic>> _formatEvolutionChain(Map<String, dynamic> chain) {
    final List<Map<String, dynamic>> result = [];

    void processChain(Map<String, dynamic> node, String? evolutionDetails) {
      final speciesName = node['species']['name'];
      final speciesId = PokeApiService.extractIdFromUrl(node['species']['url']);

      result.add({
        'name': capitalize(speciesName),
        'id': speciesId,
        'img': speciesId != null
            ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$speciesId.png'
            : '',
        'info': evolutionDetails ?? speciesName,
      });

      // Process evolutions
      final evolvesTo = node['evolves_to'] as List?;
      if (evolvesTo != null && evolvesTo.isNotEmpty) {
        for (var evolution in evolvesTo) {
          final details = _formatEvolutionDetails(evolution['evolution_details']);
          processChain(evolution, details);
        }
      }
    }

    processChain(chain, null);
    return result;
  }

  /// Formats evolution details (trigger, level, item, etc.)
  static String _formatEvolutionDetails(List<dynamic> details) {
    if (details.isEmpty) return '';

    final detail = details[0]; // Take first evolution method
    final trigger = detail['trigger']['name'];
    final minLevel = detail['min_level'];
    final item = detail['item']?['name'];
    final heldItem = detail['held_item']?['name'];
    final minHappiness = detail['min_happiness'];
    final timeOfDay = detail['time_of_day'];

    final List<String> conditions = [];

    if (trigger == 'level-up') {
      if (minLevel != null) {
        conditions.add('Level $minLevel');
      }
      if (minHappiness != null) {
        conditions.add('Happiness $minHappiness');
      }
      if (timeOfDay != null && timeOfDay.isNotEmpty) {
        conditions.add('at ${capitalize(timeOfDay)}');
      }
      if (heldItem != null) {
        conditions.add('holding ${capitalize(heldItem.replaceAll('-', ' '))}');
      }
    } else if (trigger == 'use-item') {
      if (item != null) {
        conditions.add(capitalize(item.replaceAll('-', ' ')));
      }
    } else if (trigger == 'trade') {
      conditions.add('Trade');
      if (heldItem != null) {
        conditions.add('holding ${capitalize(heldItem.replaceAll('-', ' '))}');
      }
    }

    return conditions.isNotEmpty ? conditions.join(' ') : capitalize(trigger.replaceAll('-', ' '));
  }

  /// Formats EV yield from stats
  static String _formatEvYield(List<dynamic> stats) {
    final evs = <String>[];
    for (var stat in stats) {
      final effort = stat['effort'];
      if (effort > 0) {
        final statName = _formatStatName(stat['stat']['name']);
        evs.add('$effort $statName');
      }
    }
    return evs.isNotEmpty ? evs.join(', ') : 'None';
  }

  /// Formats stat name for display
  static String _formatStatName(String statName) {
    final Map<String, String> statMap = {
      'hp': 'HP',
      'attack': 'Attack',
      'defense': 'Defense',
      'special-attack': 'Sp. Atk',
      'special-defense': 'Sp. Def',
      'speed': 'Speed',
    };
    return statMap[statName] ?? capitalize(statName);
  }

  /// Formats gender rate (-1 = genderless, 0 = 100% male, 8 = 100% female)
  static String _formatGenderRate(int? genderRate) {
    if (genderRate == null || genderRate == -1) {
      return 'Genderless';
    }
    final femalePercent = (genderRate / 8 * 100).toStringAsFixed(1);
    final malePercent = ((8 - genderRate) / 8 * 100).toStringAsFixed(1);
    return '$malePercent% ♂, $femalePercent% ♀';
  }

  /// Gets English flavor text from flavor text entries
  static String _getEnglishFlavorText(List<dynamic>? entries) {
    if (entries == null || entries.isEmpty) return 'No Pokédex entry available.';

    for (var entry in entries) {
      if (entry['language']['name'] == 'en') {
        final text = entry['flavor_text'] as String;
        return text.replaceAll('\n', ' ').replaceAll('\f', ' ');
      }
    }
    return 'No Pokédex entry available.';
  }

  /// Gets English value from a list of language-specific entries
  static String? _getEnglishValue(List<dynamic>? entries, String key) {
    if (entries == null || entries.isEmpty) return null;

    for (var entry in entries) {
      if (entry['language']['name'] == 'en') {
        return entry[key];
      }
    }
    return null;
  }

  /// Capitalizes first letter of each word
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Converts display name back to API format (e.g., "Mr Mime" -> "mr-mime")
  static String toApiFormat(String displayName) {
    if (displayName.isEmpty) return displayName;
    return displayName.toLowerCase().replaceAll(' ', '-');
  }

  /// Converts meters to feet and inches
  static String _metersToFeet(double meters) {
    final totalInches = meters * 39.3701;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }

  /// Converts kg to lbs
  static double _kgToLbs(double kg) {
    return double.parse((kg * 2.20462).toStringAsFixed(1));
  }

  /// Formats Pokemon list item for Generations view
  static Map<String, dynamic> formatPokemonListItem(
    Map<String, dynamic> pokemon,
    int index,
  ) {
    final id = pokemon['id'] ?? index;
    final name = capitalize(pokemon['name']);
    final types = (pokemon['types'] as List?)
        ?.map((t) => capitalize(t['type']['name']))
        .toList() ?? [];

    final sprites = pokemon['sprites'];
    final imageUrl = sprites?['other']?['official-artwork']?['front_default'] ??
        sprites?['front_default'] ??
        '';

    return {
      'id': id,
      'name': name,
      'types': types,
      'image': imageUrl,
    };
  }
}
