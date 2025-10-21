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
      print('PokemonDBService: Fetching from $url');

      final response = await Requests.get(url);
      print('PokemonDBService: Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load Pokemon page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.content());
      print('PokemonDBService: HTML parsed, looking for encounters...');

      final encounters = _parseEncounters(document);
      print('PokemonDBService: Found ${encounters.length} game entries');

      _cache[cacheKey] = encounters;
      return encounters;
    } catch (e) {
      print('Error fetching encounter data for $pokemonName: $e');
      print('Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  static Map<String, List<String>> _parseEncounters(Document document) {
    final Map<String, List<String>> encounters = {};

    try {
      // First, find the "Where to find" section by looking for the heading
      final headings = document.querySelectorAll('h2');
      Element? locationSection;

      for (var heading in headings) {
        if (heading.text.toLowerCase().contains('where to find')) {
          // Found the location heading, now find the next table
          var sibling = heading.nextElementSibling;
          while (sibling != null) {
            if (sibling.localName == 'div' && sibling.classes.contains('resp-scroll')) {
              locationSection = sibling;
              break;
            }
            sibling = sibling.nextElementSibling;
          }
          break;
        }
      }

      if (locationSection == null) {
        print('PokemonDBService: Could not find location section');
        return {};
      }

      // Now parse only the table in the location section
      final table = locationSection.querySelector('table.vitals-table');
      if (table == null) {
        print('PokemonDBService: No table found in location section');
        return {};
      }

      final rows = table.querySelectorAll('tbody tr');
      print('PokemonDBService: Found ${rows.length} location rows');

      for (var row in rows) {
        final cells = row.querySelectorAll('th, td');
        if (cells.length < 2) continue;

        // First cell (th) contains the game version spans
        final gameCell = cells[0];
        final gameSpans = gameCell.querySelectorAll('span.igame');

        // Extract game names from the span class names
        List<String> gameNames = [];
        for (var span in gameSpans) {
          final className = span.className;
          // Extract game name from class like "igame sword" -> "Sword"
          final gameParts = className.split(' ');
          if (gameParts.length > 1) {
            String gameName = gameParts[1]
                .split('-')
                .map((word) => word[0].toUpperCase() + word.substring(1))
                .join(' ');
            gameNames.add(gameName);
          }
        }

        // Second cell (td) contains locations
        final locationCell = cells[1];

        // Skip if it says "Location data not yet available" or "Not available"
        final cellText = locationCell.text.trim();
        if (cellText.contains('not yet available') ||
            cellText.contains('Not available in this game')) {
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
          if (cellText.isNotEmpty) {
            locations.add(cellText);
          }
        }

        // Add encounters for all game versions in this row
        if (gameNames.isNotEmpty && locations.isNotEmpty) {
          final gameKey = gameNames.join('/');
          encounters[gameKey] = locations;
          print('Added encounter: $gameKey -> ${locations.length} locations');
        }
      }

      print('PokemonDBService: Total parsed encounters: ${encounters.length}');
      for (var entry in encounters.entries) {
        print('  ${entry.key}: ${entry.value.take(3).join(", ")}${entry.value.length > 3 ? "..." : ""}');
      }
    } catch (e) {
      print('Error parsing encounter data: $e');
      print('Stack trace: ${StackTrace.current}');
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
