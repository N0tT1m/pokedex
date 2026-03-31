import 'package:requests/requests.dart';

/// Service class for interacting with the Pokemon API
/// Supports both the local Go API and PokeAPI v2 as fallback
class PokeApiService {
  static const String baseUrl = 'https://poke-api.duocore.dev:158/api/v2';

  // Cache for API responses to reduce network calls
  static final Map<String, dynamic> _cache = {};

  /// Fetches a list of all Pokemon (with pagination support)
  /// [limit] - Number of Pokemon to fetch (default: 1025 for all Pokemon through Gen 9)
  /// [offset] - Offset for pagination (default: 0)
  /// Returns a list of Pokemon with name and URL
  static Future<List<Map<String, dynamic>>> getPokemonList({
    int limit = 1025,
    int offset = 0,
  }) async {
    final cacheKey = 'pokemon_list_${limit}_$offset';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon?limit=$limit&offset=$offset',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results']);
        _cache[cacheKey] = results;
        return results;
      } else {
        throw Exception('Failed to load Pokemon list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Pokemon list: $e');
    }
  }

  /// Fetches detailed information about a specific Pokemon
  /// [identifier] - Pokemon name or ID
  /// Returns comprehensive Pokemon data including stats, types, abilities, sprites
  static Future<Map<String, dynamic>> getPokemon(String identifier) async {
    final cacheKey = 'pokemon_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load Pokemon: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Pokemon: $e');
    }
  }

  /// Fetches Pokemon species data including evolution chain, flavor text, etc.
  /// [identifier] - Pokemon species name or ID
  /// Returns species data including evolution chain URL, genera, flavor text
  static Future<Map<String, dynamic>> getPokemonSpecies(String identifier) async {
    final cacheKey = 'species_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon-species/${identifier.toLowerCase()}',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load species: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching species: $e');
    }
  }

  /// Fetches evolution chain data
  /// [id] - Evolution chain ID (obtained from species data)
  /// Returns complete evolution chain information
  static Future<Map<String, dynamic>> getEvolutionChain(int id) async {
    final cacheKey = 'evolution_$id';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get('$baseUrl/evolution-chain/$id');

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load evolution chain: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching evolution chain: $e');
    }
  }

  /// Fetches ability details
  /// [identifier] - Ability name or ID
  /// Returns ability data including effect and flavor text
  static Future<Map<String, dynamic>> getAbility(String identifier) async {
    final cacheKey = 'ability_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/ability/${identifier.toLowerCase()}',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load ability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ability: $e');
    }
  }

  /// Fetches type information
  /// [identifier] - Type name or ID
  /// Returns type data including damage relations
  static Future<Map<String, dynamic>> getType(String identifier) async {
    final cacheKey = 'type_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/type/${identifier.toLowerCase()}',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching type: $e');
    }
  }

  /// Fetches generation information
  /// [id] - Generation ID (1-9)
  /// Returns generation data including Pokemon species in that generation
  static Future<Map<String, dynamic>> getGeneration(int id) async {
    final cacheKey = 'generation_$id';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get('$baseUrl/generation/$id');

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load generation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching generation: $e');
    }
  }

  /// Fetches location area details where Pokemon can be encountered
  /// [identifier] - Location area name or ID
  /// Returns location area data
  static Future<Map<String, dynamic>> getLocationArea(String identifier) async {
    final cacheKey = 'location_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final regions = await Requests.get(
        '$baseUrl/location/regions',
      );

      if (regions.statusCode == 200) {
        final data = regions.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load location: ${regions.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching location: $e');
    }
  }

  /// Fetches Pokemon encounters for a specific Pokemon
  /// [identifier] - Pokemon name or ID
  /// Returns list of location areas where this Pokemon can be found
  static Future<List<dynamic>> getPokemonEncounters(String identifier) async {
    final cacheKey = 'encounters_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return List<dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}/encounters',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load encounters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching encounters: $e');
    }
  }

  /// Fetches the move learnset for a specific Pokemon
  /// Returns a list of moves with learn_method, type, category, power, accuracy
  static Future<List<Map<String, dynamic>>> getPokemonMoves(String identifier) async {
    final cacheKey = 'moves_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}/moves',
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(response.json());
        _cache[cacheKey] = data;
        return data;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetches type defense matchups for a specific Pokemon
  /// Returns a list of {type_name, multiplier} entries
  static Future<List<Map<String, dynamic>>> getPokemonTypeDefenses(String identifier) async {
    final cacheKey = 'typedefenses_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}/type-defenses',
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(response.json());
        _cache[cacheKey] = data;
        return data;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetches all natures with stat modifiers
  static Future<List<Map<String, dynamic>>> getNatures() async {
    const cacheKey = 'natures';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get('$baseUrl/nature');

      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results']);
        _cache[cacheKey] = results;
        return results;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetches list of all available game names
  static Future<List<String>> getGames() async {
    const cacheKey = 'games';

    if (_cache.containsKey(cacheKey)) {
      return List<String>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get('$baseUrl/games');

      if (response.statusCode == 200) {
        final data = response.json();
        final games = List<String>.from(data['games']);
        _cache[cacheKey] = games;
        return games;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetches game-specific pokedex (regional + national)
  static Future<Map<String, dynamic>> getGamePokedex(String game) async {
    final cacheKey = 'game_pokedex_$game';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokedex/game/${Uri.encodeComponent(game)}',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Helper method to extract Pokemon ID from species URL
  /// Example: "https://pokeapi.co/api/v2/pokedex/game/-species/25/" -> 25
  static int? extractIdFromUrl(String url) {
    final regex = RegExp(r'/(\d+)/?$');
    final match = regex.firstMatch(url);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Clears the cache (useful for testing or memory management)
  static void clearCache() {
    _cache.clear();
  }

  /// Gets cache size (number of cached entries)
  static int getCacheSize() {
    return _cache.length;
  }

  /// Fetches version group information (game versions)
  /// [identifier] - Version group name or ID (e.g., 'sword-shield', 'red-blue')
  /// Returns version group data including available pokedexes
  static Future<Map<String, dynamic>> getVersionGroup(String identifier) async {
    final cacheKey = 'version_group_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/version-group/${identifier.toLowerCase()}',
      );

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load version group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching version group: $e');
    }
  }

  /// Fetches pokedex information by ID
  /// [id] - Pokedex ID (e.g., 1 for 'national', 2 for 'kanto')
  /// Returns pokedex data including all Pokemon entries
  static Future<Map<String, dynamic>> getPokedex(int id) async {
    final cacheKey = 'pokedex_$id';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get('$baseUrl/pokedex/$id');

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load pokedex: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pokedex: $e');
    }
  }

  /// Fetches pokedex information by name
  /// [name] - Pokedex name (e.g., 'kanto', 'original-sinnoh')
  /// Returns pokedex data including all Pokemon entries
  static Future<Map<String, dynamic>> getPokedexByName(String name) async {
    final cacheKey = 'pokedex_$name';

    if (_cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get('$baseUrl/pokedex/$name');

      if (response.statusCode == 200) {
        final data = response.json();
        _cache[cacheKey] = data;
        return data;
      } else {
        throw Exception('Failed to load pokedex: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pokedex: $e');
    }
  }

  /// Fetches flavor text / Pokedex entries for a Pokemon across game versions
  static Future<List<Map<String, dynamic>>> getPokemonFlavorText(String identifier) async {
    final cacheKey = 'flavor_text_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}/flavor-text',
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(response.json());
        _cache[cacheKey] = data;
        return data;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetches localized names for a Pokemon (multi-language)
  static Future<List<Map<String, dynamic>>> getPokemonNames(String identifier) async {
    final cacheKey = 'names_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}/names',
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(response.json());
        _cache[cacheKey] = data;
        return data;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetches all sprites for a Pokemon across generations
  static Future<List<Map<String, dynamic>>> getPokemonAllSprites(String identifier) async {
    final cacheKey = 'sprites_all_$identifier';

    if (_cache.containsKey(cacheKey)) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await Requests.get(
        '$baseUrl/pokemon/${identifier.toLowerCase()}/sprites-all',
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(response.json());
        _cache[cacheKey] = data;
        return data;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
