import 'dart:convert';
import 'package:requests/requests.dart';

class PokemonDBService {
  // Use the local Go API for encounter data (falls back to empty if unavailable)
  static const String _apiBaseUrl = 'https://poke-api.duocore.dev/api/v2';
  static final Map<String, Map<String, List<String>>> _cache = {};

  /// Fetch encounter locations for a Pokemon from the local API
  /// Returns a map of game names to list of locations
  static Future<Map<String, List<String>>> getEncounterLocations(
      String pokemonName) async {
    final cacheKey = pokemonName.toLowerCase();

    if (_cache.containsKey(cacheKey)) {
      return Map<String, List<String>>.from(_cache[cacheKey]!);
    }

    try {
      final url = '$_apiBaseUrl/pokemon/${pokemonName.toLowerCase()}/encounters';
      final response = await Requests.get(url);

      if (response.statusCode != 200) {
        return {};
      }

      final List<dynamic> data = response.json();
      final Map<String, List<String>> encounters = {};

      for (var entry in data) {
        final games = List<String>.from(entry['games'] ?? []);
        final locations = List<String>.from(entry['locations'] ?? []);
        if (games.isNotEmpty && locations.isNotEmpty) {
          final gameKey = games.join('/');
          encounters[gameKey] = locations;
        }
      }

      _cache[cacheKey] = encounters;
      return encounters;
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
}
