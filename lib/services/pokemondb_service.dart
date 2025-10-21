import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:requests/requests.dart';

class PokemonDBService {
  static const String _baseUrl = 'https://pokemondb.net';
  static final Map<String, Map<String, List<String>>> _cache = {};

  /// Fetch encounter locations for a Pokemon from PokemonDB
  /// Returns a map of game names to list of locations
  static Future<Map<String, List<String>>> getEncounterLocations(
      String pokemonName) async {
    final cacheKey = pokemonName.toLowerCase();

    if (_cache.containsKey(cacheKey)) {
      return Map<String, List<String>>.from(_cache[cacheKey]!);
    }

    try {
      final url = '$_baseUrl/pokedex/${pokemonName.toLowerCase()}';
      final response = await Requests.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to load Pokemon page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.content());
      final encounters = _parseEncounters(document);

      _cache[cacheKey] = encounters;
      return encounters;
    } catch (e) {
      print('Error fetching encounter data for $pokemonName: $e');
      return {};
    }
  }

  static Map<String, List<String>> _parseEncounters(Document document) {
    final Map<String, List<String>> encounters = {};

    try {
      // Find the locations section
      final locationsDiv = document.querySelector('#dex-locations');
      if (locationsDiv == null) return {};

      // Find the table with location data
      final table = locationsDiv.querySelector('table');
      if (table == null) return {};

      final rows = table.querySelectorAll('tbody tr');

      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length < 2) continue;

        // First cell contains the game version
        final gameCell = cells[0];
        String? gameVersion = gameCell.text.trim();

        // Second cell contains locations
        final locationCell = cells[1];

        // Skip if it says "Location data not yet available"
        if (locationCell.text.contains('Location data not yet available')) {
          continue;
        }

        // Extract location names from links or text
        final locationLinks = locationCell.querySelectorAll('a');
        final List<String> locations = [];

        if (locationLinks.isNotEmpty) {
          for (var link in locationLinks) {
            final locationName = link.text.trim();
            if (locationName.isNotEmpty) {
              locations.add(locationName);
            }
          }
        } else {
          // If no links, just get the text
          final locationText = locationCell.text.trim();
          if (locationText.isNotEmpty &&
              !locationText.contains('not yet available')) {
            locations.add(locationText);
          }
        }

        if (gameVersion.isNotEmpty && locations.isNotEmpty) {
          encounters[gameVersion] = locations;
        }
      }
    } catch (e) {
      print('Error parsing encounter data: $e');
    }

    return encounters;
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

  /// Map common game version names to PokemonDB format
  static String? normalizeGameVersion(String? gameVersion) {
    if (gameVersion == null) return null;

    final Map<String, String> gameMap = {
      'Scarlet/Violet': 'Scarlet/Violet',
      'Sword/Shield': 'Sword/Shield',
      'Brilliant Diamond/Shining Pearl': 'Brilliant Diamond/Shining Pearl',
      'Legends: Arceus': 'Legends: Arceus',
      'Let\'s Go Pikachu/Eevee': 'Let\'s Go Pikachu/Eevee',
      'Ultra Sun/Ultra Moon': 'Ultra Sun/Ultra Moon',
      'Sun/Moon': 'Sun/Moon',
      'Omega Ruby/Alpha Sapphire': 'Omega Ruby/Alpha Sapphire',
      'X/Y': 'X/Y',
      'Black 2/White 2': 'Black 2/White 2',
      'Black/White': 'Black/White',
      'HeartGold/SoulSilver': 'HeartGold/SoulSilver',
      'Platinum': 'Platinum',
      'Diamond/Pearl': 'Diamond/Pearl',
      'Emerald': 'Emerald',
      'FireRed/LeafGreen': 'FireRed/LeafGreen',
      'Ruby/Sapphire': 'Ruby/Sapphire',
      'Crystal': 'Crystal',
      'Gold/Silver': 'Gold/Silver',
      'Yellow': 'Yellow',
      'Red/Blue': 'Red/Blue',
    };

    return gameMap[gameVersion] ?? gameVersion;
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
}
