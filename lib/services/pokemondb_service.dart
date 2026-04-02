import 'package:requests/requests.dart';

/// Region-aware game abbreviation map.
/// Ambiguous abbreviations (S, B, Y, G) are resolved by region.
const Map<String, Map<String, String>> _regionGameAbbreviations = {
  'Kanto': {
    'R': 'Red',
    'B': 'Blue',
    'Y': 'Yellow',
    'FR': 'FireRed',
    'LG': 'LeafGreen',
    'LGP': "Let's Go Pikachu",
    'LGE': "Let's Go Eevee",
  },
  'Johto': {
    'G': 'Gold',
    'S': 'Silver',
    'C': 'Crystal',
    'HG': 'HeartGold',
    'SS': 'SoulSilver',
  },
  'Hoenn': {
    'Ru': 'Ruby',
    'Sa': 'Sapphire',
    'E': 'Emerald',
    'OR': 'Omega Ruby',
    'AS': 'Alpha Sapphire',
  },
  'Sinnoh': {
    'D': 'Diamond',
    'P': 'Pearl',
    'Pt': 'Platinum',
    'BD': 'Brilliant Diamond',
    'SP': 'Shining Pearl',
  },
  'Unova': {
    'B': 'Black',
    'W': 'White',
    'B2': 'Black 2',
    'W2': 'White 2',
  },
  'Kalos': {
    'X': 'X',
    'Y': 'Y',
  },
  'Alola': {
    'S': 'Sun',
    'M': 'Moon',
    'US': 'Ultra Sun',
    'UM': 'Ultra Moon',
  },
  'Galar': {
    'Sw': 'Sword',
    'Sh': 'Shield',
  },
  'Hisui': {
    'LA': 'Legends: Arceus',
  },
  'Paldea': {
    'S': 'Scarlet',
    'V': 'Violet',
  },
};

/// Expand a game abbreviation using the region for disambiguation.
String _expandGame(String abbr, String region) {
  final regionMap = _regionGameAbbreviations[region];
  if (regionMap != null && regionMap.containsKey(abbr)) {
    return regionMap[abbr]!;
  }
  // Fallback: search all regions (for any region not yet listed)
  for (var map in _regionGameAbbreviations.values) {
    if (map.containsKey(abbr)) return map[abbr]!;
  }
  return abbr;
}

class PokemonDBService {
  static const String _apiBaseUrl = 'https://poke-api.duocore.dev:158/api/v2';
  static final Map<String, Map<String, List<String>>> _cache = {};

  /// Fetch encounter locations for a Pokemon from the location API
  /// Returns a map of "Region - Route" to list of detail strings
  static Future<Map<String, List<String>>> getEncounterLocations(
      String pokemonName) async {
    final cacheKey = pokemonName.toLowerCase();

    if (_cache.containsKey(cacheKey)) {
      return Map<String, List<String>>.from(_cache[cacheKey]!);
    }

    try {
      final url = '$_apiBaseUrl/location/pokemon/${pokemonName.toLowerCase()}';
      final response = await Requests.get(url);

      if (response.statusCode != 200) {
        return {};
      }

      final data = response.json();
      final List<dynamic> encounters = data['encounters'] ?? [];
      final Map<String, List<String>> result = {};

      for (var entry in encounters) {
        final region = entry['region'] ?? '';
        final route = entry['route_name'] ?? '';
        final games = List<String>.from(entry['games'] ?? []);
        final method = entry['encounter_method'] ?? '';
        final rarity = entry['rarity'] ?? '';
        final levelRange = entry['level_range'] ?? '';
        final timeOfDay = entry['time_of_day'] ?? '';

        final key = '$region - $route';
        final details = <String>[];
        if (games.isNotEmpty) {
          final expandedGames = games
              .map((g) => _expandGame(g, region))
              .toList();
          details.add(expandedGames.join(', '));
        }
        if (method.isNotEmpty) details.add(method);
        if (levelRange.isNotEmpty && levelRange != '—') details.add('Lv.$levelRange');
        if (rarity.isNotEmpty) details.add(rarity);
        if (timeOfDay.isNotEmpty && timeOfDay != 'Day, Night') details.add(timeOfDay);

        result.putIfAbsent(key, () => []);
        result[key]!.add(details.join(' | '));
      }

      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Get a simplified list of all locations across all games
  static List<String> getAllLocations(Map<String, List<String>> encounters) {
    final Set<String> allLocations = {};
    for (var locations in encounters.values) {
      allLocations.addAll(locations);
    }
    return allLocations.toList()..sort();
  }

  /// Get locations for a specific game
  static List<String>? getLocationsForGame(
      Map<String, List<String>> encounters, String gameVersion) {
    // Try exact match first
    if (encounters.containsKey(gameVersion)) {
      return encounters[gameVersion];
    }

    // Try partial match
    for (var key in encounters.keys) {
      if (key.toLowerCase().contains(gameVersion.toLowerCase()) ||
          gameVersion.toLowerCase().contains(key.toLowerCase())) {
        return encounters[key];
      }
    }

    return null;
  }

  /// Format encounter data as a readable string
  static String formatEncountersForDisplay(Map<String, List<String>> encounters) {
    if (encounters.isEmpty) {
      return 'No encounter data available';
    }

    final StringBuffer buffer = StringBuffer();
    for (var entry in encounters.entries) {
      buffer.write('${entry.key}: ');
      buffer.write(entry.value.join(', '));
      buffer.write('\n');
    }

    return buffer.toString().trim();
  }

  /// Clears the cache
  static void clearCache() {
    _cache.clear();
  }

  // ---------------------------------------------------------------------------
  // Raid events
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>>? _raidCache;
  static List<Map<String, dynamic>>? _activeRaidCache;

  /// Fetch all raid events, active ones first.
  static Future<List<Map<String, dynamic>>> getRaidEvents() async {
    if (_raidCache != null) return _raidCache!;
    try {
      final response = await Requests.get('$_apiBaseUrl/news/raids');
      if (response.statusCode != 200) return [];
      final data = response.json();
      _raidCache = List<Map<String, dynamic>>.from(data['results'] ?? []);
      return _raidCache!;
    } catch (e) {
      return [];
    }
  }

  /// Fetch only currently active raid events.
  static Future<List<Map<String, dynamic>>> getActiveRaids() async {
    if (_activeRaidCache != null) return _activeRaidCache!;
    try {
      final response = await Requests.get('$_apiBaseUrl/news/raids/active');
      if (response.statusCode != 200) return [];
      final data = response.json();
      _activeRaidCache = List<Map<String, dynamic>>.from(data['results'] ?? []);
      return _activeRaidCache!;
    } catch (e) {
      return [];
    }
  }

  /// Fetch counters for a specific raid Pokemon.
  /// Pass [teraType] to filter to a specific tera type when applicable.
  static Future<List<Map<String, dynamic>>> getRaidCounters(
      String pokemonName, {String? teraType}) async {
    try {
      var url = '$_apiBaseUrl/news/raids/${pokemonName.toLowerCase()}';
      if (teraType != null && teraType.isNotEmpty) {
        url += '?tera_type=${Uri.encodeComponent(teraType)}';
      }
      final response = await Requests.get(url);
      if (response.statusCode != 200) return [];
      final data = response.json();
      return List<Map<String, dynamic>>.from(data['counters'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Clear raid caches (call after re-running the spider).
  static void clearRaidCache() {
    _raidCache = null;
    _activeRaidCache = null;
  }
}
