import 'pokeapi_service.dart';

/// Service for fetching detailed evolution method information
class EvolutionService {
  /// Get full evolution chain with detailed methods for a Pokemon
  static Future<List<Map<String, dynamic>>> getEvolutionDetails(String pokemonName) async {
    try {
      final species = await PokeApiService.getPokemonSpecies(pokemonName.toLowerCase());
      final evoUrl = species['evolution_chain']?['url'] as String?;
      if (evoUrl == null) return [];

      final id = PokeApiService.extractIdFromUrl(evoUrl);
      if (id == null) return [];

      final chain = await PokeApiService.getEvolutionChain(id);
      final results = <Map<String, dynamic>>[];
      _parseChain(chain['chain'], results);
      return results;
    } catch (e) {
      return [];
    }
  }

  static void _parseChain(Map<String, dynamic> link, List<Map<String, dynamic>> results) {
    final speciesName = link['species']['name'] as String;
    final evolvesTo = link['evolves_to'] as List;

    for (var evo in evolvesTo) {
      final targetName = evo['species']['name'] as String;
      final details = evo['evolution_details'] as List;

      for (var detail in details) {
        results.add({
          'from': _formatName(speciesName),
          'to': _formatName(targetName),
          'fromApi': speciesName,
          'toApi': targetName,
          'trigger': detail['trigger']?['name'] ?? 'unknown',
          'min_level': detail['min_level'],
          'item': detail['item']?['name'],
          'held_item': detail['held_item']?['name'],
          'min_happiness': detail['min_happiness'],
          'min_affection': detail['min_affection'],
          'min_beauty': detail['min_beauty'],
          'time_of_day': detail['time_of_day'] != '' ? detail['time_of_day'] : null,
          'known_move': detail['known_move']?['name'],
          'known_move_type': detail['known_move_type']?['name'],
          'location': detail['location']?['name'],
          'needs_overworld_rain': detail['needs_overworld_rain'] == true,
          'party_species': detail['party_species']?['name'],
          'party_type': detail['party_type']?['name'],
          'gender': detail['gender'],
          'relative_physical_stats': detail['relative_physical_stats'],
          'turn_upside_down': detail['turn_upside_down'] == true,
          'trade_species': detail['trade_species']?['name'],
        });
      }

      _parseChain(evo, results);
    }
  }

  /// Build a human-readable description of an evolution method
  static String describeMethod(Map<String, dynamic> evo) {
    final trigger = evo['trigger'] as String;
    final parts = <String>[];

    switch (trigger) {
      case 'level-up':
        if (evo['min_level'] != null) {
          parts.add('Level ${evo['min_level']}');
        } else {
          parts.add('Level up');
        }
        break;
      case 'trade':
        parts.add('Trade');
        if (evo['held_item'] != null) {
          parts.add('holding ${_formatName(evo['held_item'])}');
        }
        if (evo['trade_species'] != null) {
          parts.add('for ${_formatName(evo['trade_species'])}');
        }
        break;
      case 'use-item':
        if (evo['item'] != null) {
          parts.add('Use ${_formatName(evo['item'])}');
        } else {
          parts.add('Use item');
        }
        break;
      case 'shed':
        parts.add('Empty party slot + Poke Ball in bag at level 20');
        break;
      case 'spin':
        parts.add('Spin and strike a pose');
        break;
      case 'tower-of-darkness':
        parts.add('Train in Tower of Darkness');
        break;
      case 'tower-of-waters':
        parts.add('Train in Tower of Waters');
        break;
      case 'three-critical-hits':
        parts.add('Land 3 critical hits in one battle');
        break;
      case 'take-damage':
        parts.add('Travel under stone bridge after taking 49+ damage');
        break;
      case 'other':
        parts.add('Special method');
        break;
      default:
        parts.add(_formatName(trigger));
    }

    if (evo['min_happiness'] != null) parts.add('Happiness ≥ ${evo['min_happiness']}');
    if (evo['min_affection'] != null) parts.add('Affection ≥ ${evo['min_affection']}');
    if (evo['min_beauty'] != null) parts.add('Beauty ≥ ${evo['min_beauty']}');
    if (evo['time_of_day'] != null) parts.add('(${evo['time_of_day']})');
    if (evo['known_move'] != null) parts.add('knowing ${_formatName(evo['known_move'])}');
    if (evo['known_move_type'] != null) parts.add('knowing a ${_formatName(evo['known_move_type'])}-type move');
    if (evo['location'] != null) parts.add('at ${_formatName(evo['location'])}');
    if (evo['needs_overworld_rain'] == true) parts.add('while raining');
    if (evo['party_species'] != null) parts.add('with ${_formatName(evo['party_species'])} in party');
    if (evo['party_type'] != null) parts.add('with ${_formatName(evo['party_type'])}-type in party');
    if (evo['turn_upside_down'] == true) parts.add('holding console upside down');

    if (evo['gender'] != null) {
      parts.add(evo['gender'] == 1 ? '(Female only)' : '(Male only)');
    }

    if (evo['relative_physical_stats'] != null) {
      final rps = evo['relative_physical_stats'] as int;
      if (rps == 1) parts.add('(Attack > Defense)');
      if (rps == -1) parts.add('(Attack < Defense)');
      if (rps == 0) parts.add('(Attack = Defense)');
    }

    return parts.join(' ');
  }

  static String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
