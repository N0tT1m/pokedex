import 'pokeapi_service.dart';

/// Service for Pokemon breeding calculations
class BreedingService {
  static final Map<String, List<String>> _eggGroupCache = {};

  /// Check if two Pokemon can breed.
  /// Returns compatibility info plus species details useful for the UI
  /// (egg cycles, gender rate, growth rate).
  static Future<Map<String, dynamic>> checkCompatibility(String pokemon1, String pokemon2) async {
    try {
      final species1 = await PokeApiService.getPokemonSpecies(pokemon1.toLowerCase());
      final species2 = await PokeApiService.getPokemonSpecies(pokemon2.toLowerCase());

      final eggGroups1 = (species1['egg_groups'] as List)
          .map((eg) => eg['name'] as String)
          .toList();
      final eggGroups2 = (species2['egg_groups'] as List)
          .map((eg) => eg['name'] as String)
          .toList();

      // Species details the UI can use (egg cycles, gender ratio, etc.)
      final speciesInfo1 = _extractSpeciesInfo(species1);
      final speciesInfo2 = _extractSpeciesInfo(species2);

      Map<String, dynamic> base = {
        'eggGroups1': eggGroups1,
        'eggGroups2': eggGroups2,
        'species1': speciesInfo1,
        'species2': speciesInfo2,
      };

      // Ditto can breed with anything except Undiscovered
      bool dittoInvolved = eggGroups1.contains('ditto') || eggGroups2.contains('ditto');
      bool undiscovered = eggGroups1.contains('no-eggs') || eggGroups2.contains('no-eggs');

      if (undiscovered && !dittoInvolved) {
        return {
          ...base,
          'compatible': false,
          'reason': 'One or both Pokémon are in the Undiscovered egg group and cannot breed.',
        };
      }

      if (dittoInvolved && !undiscovered) {
        final nonDitto = eggGroups1.contains('ditto') ? pokemon2 : pokemon1;
        return {
          ...base,
          'compatible': true,
          'reason': 'Ditto can breed with any compatible Pokémon. '
              'Offspring will always be ${_formatName(nonDitto)}.',
        };
      }

      // Check for shared egg groups
      final sharedGroups = eggGroups1.where((g) => eggGroups2.contains(g)).toList();

      if (sharedGroups.isNotEmpty) {
        return {
          ...base,
          'compatible': true,
          'reason': 'Shared egg group(s): ${sharedGroups.map(_formatEggGroup).join(", ")}',
          'sharedGroups': sharedGroups,
        };
      }

      return {
        ...base,
        'compatible': false,
        'reason': 'No shared egg groups. These Pokémon cannot breed with each other.',
      };
    } catch (e) {
      return {
        'compatible': false,
        'reason': 'Error checking compatibility: $e',
      };
    }
  }

  /// Extract useful species metadata from the species response.
  static Map<String, dynamic> _extractSpeciesInfo(Map<String, dynamic> species) {
    final genderRate = species['gender_rate']; // -1=genderless, 0=always M, 8=always F
    String genderText;
    if (genderRate == -1) {
      genderText = 'Genderless';
    } else if (genderRate == 0) {
      genderText = '100% Male';
    } else if (genderRate == 8) {
      genderText = '100% Female';
    } else if (genderRate is int) {
      final femalePct = (genderRate / 8 * 100).toStringAsFixed(1);
      final malePct = (100 - genderRate / 8 * 100).toStringAsFixed(1);
      genderText = '$malePct% Male, $femalePct% Female';
    } else {
      genderText = 'Unknown';
    }

    final hatchCounter = species['hatch_counter'];
    final int eggCycles = (hatchCounter is int) ? hatchCounter : 0;
    final int baseSteps = eggCycles * 257;

    return {
      'genderRate': genderRate,
      'genderText': genderText,
      'eggCycles': eggCycles,
      'baseSteps': baseSteps,
      'halfSteps': (baseSteps / 2).round(), // with Flame Body / Magma Armor
      'growthRate': species['growth_rate']?['name'] ?? '',
    };
  }

  /// Get all Pokemon in an egg group
  /// Note: No egg-group endpoint is available in the API, so this returns an empty list.
  static Future<List<Map<String, dynamic>>> getEggGroupMembers(String eggGroup) async {
    return [];
  }

  /// Get egg moves for a Pokemon
  static Future<List<Map<String, dynamic>>> getEggMoves(String pokemonName) async {
    try {
      final moves = await PokeApiService.getPokemonMoves(pokemonName.toLowerCase());

      final eggMoves = <Map<String, dynamic>>[];
      for (var move in moves) {
        final learnMethod = (move['learn_method'] as String?) ?? '';
        if (learnMethod.toLowerCase().contains('egg')) {
          final name = move['name'] as String;
          eggMoves.add({
            'name': _formatMoveName(name),
            'apiName': name,
          });
        }
      }

      return eggMoves;
    } catch (e) {
      return [];
    }
  }

  static String _formatEggGroup(String group) {
    return group.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  static String _formatMoveName(String name) {
    return name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  static String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  /// All egg groups for reference
  static const List<String> allEggGroups = [
    'monster', 'water1', 'water2', 'water3', 'bug', 'flying',
    'field', 'fairy', 'grass', 'human-like', 'mineral', 'amorphous',
    'dragon', 'ditto', 'no-eggs',
  ];

  static String formatEggGroupName(String group) => _formatEggGroup(group);
}
