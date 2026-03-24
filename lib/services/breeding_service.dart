import 'pokeapi_service.dart';

/// Service for Pokemon breeding calculations
class BreedingService {
  static final Map<String, List<String>> _eggGroupCache = {};

  /// Check if two Pokemon can breed
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

      // Ditto can breed with anything except Undiscovered
      bool dittoInvolved = eggGroups1.contains('ditto') || eggGroups2.contains('ditto');
      bool undiscovered = eggGroups1.contains('no-eggs') || eggGroups2.contains('no-eggs');

      if (undiscovered && !dittoInvolved) {
        return {
          'compatible': false,
          'reason': 'One or both Pokemon are in the Undiscovered egg group',
          'eggGroups1': eggGroups1,
          'eggGroups2': eggGroups2,
        };
      }

      if (dittoInvolved && !undiscovered) {
        return {
          'compatible': true,
          'reason': 'Ditto can breed with any compatible Pokemon',
          'eggGroups1': eggGroups1,
          'eggGroups2': eggGroups2,
        };
      }

      // Check for shared egg groups
      final sharedGroups = eggGroups1.where((g) => eggGroups2.contains(g)).toList();

      if (sharedGroups.isNotEmpty) {
        return {
          'compatible': true,
          'reason': 'Shared egg group(s): ${sharedGroups.map(_formatEggGroup).join(", ")}',
          'sharedGroups': sharedGroups,
          'eggGroups1': eggGroups1,
          'eggGroups2': eggGroups2,
        };
      }

      return {
        'compatible': false,
        'reason': 'No shared egg groups',
        'eggGroups1': eggGroups1,
        'eggGroups2': eggGroups2,
      };
    } catch (e) {
      return {
        'compatible': false,
        'reason': 'Error checking compatibility: $e',
      };
    }
  }

  /// Get all Pokemon in an egg group
  static Future<List<Map<String, dynamic>>> getEggGroupMembers(String eggGroup) async {
    try {
      final cacheKey = eggGroup.toLowerCase();
      if (_eggGroupCache.containsKey(cacheKey)) {
        return _eggGroupCache[cacheKey]!.map((name) => {'name': name}).toList();
      }

      final response = await _fetchEggGroup(eggGroup);
      final members = (response['pokemon_species'] as List)
          .map((p) => p['name'] as String)
          .toList();
      _eggGroupCache[cacheKey] = members;

      return members.map((name) => {'name': name}).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> _fetchEggGroup(String eggGroup) async {
    final response = await PokeApiService.getPokemonSpecies(eggGroup);
    return response;
  }

  /// Get egg moves for a Pokemon
  static Future<List<Map<String, dynamic>>> getEggMoves(String pokemonName) async {
    try {
      final data = await PokeApiService.getPokemon(pokemonName.toLowerCase());
      final moves = data['moves'] as List;

      final eggMoves = <Map<String, dynamic>>[];
      for (var move in moves) {
        final versionDetails = move['version_group_details'] as List;
        for (var detail in versionDetails) {
          if (detail['move_learn_method']['name'] == 'egg') {
            eggMoves.add({
              'name': _formatMoveName(move['move']['name']),
              'apiName': move['move']['name'],
              'version': detail['version_group']['name'],
            });
            break;
          }
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

  /// All egg groups for reference
  static const List<String> allEggGroups = [
    'monster', 'water1', 'water2', 'water3', 'bug', 'flying',
    'field', 'fairy', 'grass', 'human-like', 'mineral', 'amorphous',
    'dragon', 'ditto', 'no-eggs',
  ];

  static String formatEggGroupName(String group) => _formatEggGroup(group);
}
