import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';
import '../services/pokemondb_service.dart';
import '../services/nature_recommendation_service.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Map<String, dynamic>? _pokemonData;
  String? pokemon;
  List<String> pokemonNames = [];
  List<String> names = [];
  Map<String, dynamic> tableDataFormatted = {};
  List<String> text = [];
  List<String> headers = [];
  Map<String, dynamic> mappedData = {};
  List<String> data = [];
  Map<String, dynamic> formattedOutput = {};
  List<String> pokemonLocations = [];
  List<Widget> listOfWidgets = [];
  List<Map<String, dynamic>> listOfEvolution = [];
  List<Map<String, dynamic>> evolutions = [];
  List<Map<String, dynamic>> _typeDefenses = [];
  List<Map<String, dynamic>> _moveLearnset = [];
  List<Map<String, dynamic>> _flavorTextEntries = [];
  List<Map<String, dynamic>> _pokemonNames = [];
  List<Map<String, dynamic>> _allSprites = [];
  String _biology = '';
  List<Map<String, dynamic>> _heldItems = [];
  List<Map<String, dynamic>> _gameLocations = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _getPokemon().then((value) {
      if (mounted) {
        setState(() => names = value);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() => errorMessage = 'Failed to load Pokemon list: $error');
      }
    });
  }

  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<List<String>> _getPokemon() async {
    try {
      final pokemonList = await PokeApiService.getPokemonList(limit: 1025);
      List<String> names = pokemonList
          .map((p) => PokemonDataFormatter.capitalize(p['name']))
          .toList();
      return names;
    } catch (e) {
      print('Error fetching Pokemon list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _makeRequest(String pokemon) async {
    try {
      // Reset state for new search
      text.clear();
      headers.clear();
      data.clear();
      tableDataFormatted.clear();
      mappedData.clear();
      pokemonLocations.clear();
      listOfEvolution.clear();
      evolutions.clear();
      _flavorTextEntries = [];
      _pokemonNames = [];
      _allSprites = [];
      _biology = '';
      _heldItems = [];
      _gameLocations = [];

      // Convert display name to API format (e.g., "Mr Mime" -> "mr-mime")
      final apiName = PokemonDataFormatter.toApiFormat(pokemon);

      // Fetch data from PokeAPI
      final pokemonData = await PokeApiService.getPokemon(apiName);
      final speciesData = await PokeApiService.getPokemonSpecies(apiName);

      // Get evolution chain
      Map<String, dynamic>? evolutionData;
      final evolutionChainUrl = speciesData['evolution_chain']?['url'];
      if (evolutionChainUrl != null) {
        final evolutionId = PokeApiService.extractIdFromUrl(evolutionChainUrl);
        if (evolutionId != null) {
          evolutionData = await PokeApiService.getEvolutionChain(evolutionId);
        }
      }

      // Format the data using our formatter
      final formattedData = await PokemonDataFormatter.formatPokemonData(
        pokemonData,
        speciesData,
        evolutionData,
      );

      // Fetch type defenses, moves, flavor text, names, and sprites
      try {
        _typeDefenses = await PokeApiService.getPokemonTypeDefenses(apiName);
      } catch (e) {
        _typeDefenses = [];
      }
      try {
        _moveLearnset = await PokeApiService.getPokemonMoves(apiName);
      } catch (e) {
        _moveLearnset = [];
      }
      try {
        _flavorTextEntries = await PokeApiService.getPokemonFlavorText(apiName);
      } catch (e) {
        _flavorTextEntries = [];
      }
      try {
        _pokemonNames = await PokeApiService.getPokemonNames(apiName);
      } catch (e) {
        _pokemonNames = [];
      }
      try {
        _allSprites = await PokeApiService.getPokemonAllSprites(apiName);
      } catch (e) {
        _allSprites = [];
      }

      // Fetch Bulbapedia data (biology, held items, game locations)
      try {
        final bioRes = await Requests.get('${PokeApiService.baseUrl}/pokemon/$apiName/biology');
        if (bioRes.statusCode == 200) _biology = bioRes.json()['biology'] as String? ?? '';
      } catch (_) {}
      try {
        final heldRes = await Requests.get('${PokeApiService.baseUrl}/pokemon/$apiName/held-items');
        if (heldRes.statusCode == 200) {
          _heldItems = List<Map<String, dynamic>>.from(heldRes.json()['held_items'] ?? []);
        }
      } catch (_) {}
      try {
        final locRes = await Requests.get('${PokeApiService.baseUrl}/pokemon/$apiName/game-locations');
        if (locRes.statusCode == 200) {
          _gameLocations = List<Map<String, dynamic>>.from(locRes.json()['locations'] ?? []);
        }
      } catch (_) {}

      // Fetch encounter locations from PokemonDB
      try {
        print('Fetching encounter data for: $apiName');
        final encounterData = await PokemonDBService.getEncounterLocations(apiName);
        print('Encounter data received: ${encounterData.keys.length} games found');
        pokemonLocations = [];

        // Format encounter data: "Game Version: Location1, Location2, ..."
        for (var entry in encounterData.entries) {
          final game = entry.key;
          final locations = entry.value;
          print('Game: $game, Locations: ${locations}');
          if (locations.isNotEmpty) {
            pokemonLocations.add('$game: ${locations.join(', ')}');
          }
        }
      } catch (e) {
        print('Could not fetch encounter locations from PokemonDB: $e');
        // Don't show the full error to user, just a simple message
        pokemonLocations = ['Unable to load location data'];
      }

      // Update formattedData with locations
      formattedData['locations'] = pokemonLocations;

      return formattedData;
    } catch (e) {
      print('Error fetching Pokemon data: $e');
      return {
        'image': '',
        'name': 'Error',
        'titles': ['Error'],
        'data': {
          'Pokédex Data': {'Error': 'Failed to load Pokemon data'},
        },
        'evolution': {},
        'locations': [],
      };
    }
  }

  Widget getPokemonWidget() {
    final List<Widget> locationWidgets = [];

    for (var i = 0; i < pokemonLocations.length; i++) {
      final parts = pokemonLocations[i].split(': ');
      if (parts.length >= 2) {
        locationWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parts[0],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                parts.sublist(1).join(': '),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        );
      } else {
        locationWidgets.add(
          Text(pokemonLocations[i], style: const TextStyle(fontSize: 14)),
        );
      }
      if (i < pokemonLocations.length - 1) {
        locationWidgets.add(const Divider(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: locationWidgets,
    );
  }

  Widget getEggs() {
    if (_pokemonData == null) return const SizedBox.shrink();

    final breedingData = _pokemonData!['data']?['Breeding'] as Map<String, dynamic>?;
    if (breedingData == null) return const SizedBox.shrink();

    final eggGroups = breedingData['Egg Groups'] ?? 'N/A';
    final gender = breedingData['Gender'] ?? 'N/A';
    final eggCycles = breedingData['Egg Cycles'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Egg Groups: $eggGroups',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'Pokemon in the same egg group can breed together. '
          '${eggGroups == 'Undiscovered' || eggGroups == 'N/A' ? 'This Pokemon cannot breed.' : 'Pair this Pokemon with others in the ${eggGroups.toString().replaceAll(";", " or ")} group(s) to produce eggs.'}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 10),
        Text(
          'Gender: $gender',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          gender.toString().contains('Genderless')
              ? 'Genderless Pokemon can only breed with Ditto.'
              : 'Breeding requires one male and one female from the same egg group. '
                'The offspring is always the same species as the mother (or non-Ditto parent).',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 10),
        Text(
          'Egg Cycles: $eggCycles',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'Each egg cycle is 257 steps. More cycles means longer to hatch. '
          'Pokemon with Flame Body or Magma Armor in your party halve the steps needed.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 10),
        _buildBreedingTipsCard(),
      ],
    );
  }

  Widget _buildBreedingTipsCard() {
    final abilities = _getSafeData('data', 'Pokédex Data', 'Abilities');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
              SizedBox(width: 4),
              Text('Breeding Tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ability Inheritance: Mothers have an 80% chance to pass down their ability. '
            'Hidden Abilities (marked with "H") can only be passed down if the parent has it. '
            'Males and genderless Pokemon can pass Hidden Abilities only when breeding with Ditto.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
          ),
          if (abilities.contains('(H)') || abilities.toLowerCase().contains('hidden')) ...[
            const SizedBox(height: 4),
            Text(
              'This Pokemon has a Hidden Ability. To breed for it, use a parent that already has '
              'the Hidden Ability — there is a 60% chance it will be passed to the offspring.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Nature: Have a parent hold an Everstone to guarantee its Nature passes down.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 4),
          Text(
            'IVs: Have a parent hold a Destiny Knot to pass down 5 of the 12 combined IVs instead of 3.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  int getPokemonLength() {
    return pokemonLocations.length;
  }

  String _getSafeData(String key1, [String? key2, String? key3]) {
    if (_pokemonData == null) return 'N/A';

    try {
      if (key2 == null) {
        return _pokemonData![key1]?.toString() ?? 'N/A';
      } else if (key3 == null) {
        return _pokemonData![key1]?[key2]?.toString() ?? 'N/A';
      } else {
        return _pokemonData![key1]?[key2]?[key3]?.toString() ?? 'N/A';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  dynamic _getSafeList(String key) {
    if (_pokemonData == null) return [];
    return _pokemonData![key] ?? [];
  }

  Widget _buildRecommendedNatureCard() {
    if (_pokemonData == null) return const SizedBox.shrink();

    final baseStatsRaw = _pokemonData!['data']?['Base Stats'] as Map<String, dynamic>?;
    if (baseStatsRaw == null) return const SizedBox.shrink();

    final baseStats = <String, int>{};
    for (var entry in baseStatsRaw.entries) {
      final val = int.tryParse(entry.value.toString());
      if (val != null) baseStats[entry.key] = val;
    }

    final pokemonName = _pokemonData!['name']?.toString() ?? '';
    final competitiveNatures = NatureRecommendationService.getCompetitiveNatures(pokemonName, baseStats);
    final ingameNatures = NatureRecommendationService.getIngameNatures(pokemonName, baseStats);

    if (competitiveNatures.isEmpty && ingameNatures.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended Natures',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // In-Game section
              if (ingameNatures.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.videogame_asset, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'In-Game (Story)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Best for beating the game — max damage, simple picks',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                ...ingameNatures.map((n) => _buildNatureRow(n, Colors.blue.shade700)),
                const SizedBox(height: 12),
              ],

              // Competitive section
              if (competitiveNatures.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.emoji_events, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Competitive (PvP)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Optimized for ranked battles and team roles',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                ...competitiveNatures.map((n) => _buildNatureRow(n, Colors.amber.shade700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNatureRow(Map<String, String> n, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, size: 16, color: accentColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${n['nature']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${n['reason']}',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
                Text(
                  '${n['role']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDefensesCard() {
    if (_typeDefenses.isEmpty) return const SizedBox.shrink();

    final weaknesses = _typeDefenses.where((t) => (t['multiplier'] as num) > 1).toList();
    final resistances = _typeDefenses.where((t) => (t['multiplier'] as num) < 1 && (t['multiplier'] as num) > 0).toList();
    final immunities = _typeDefenses.where((t) => (t['multiplier'] as num) == 0).toList();

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type Defenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (weaknesses.isNotEmpty) ...[
                Text('Weak to:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: weaknesses.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${t['type_name']} ${t['multiplier']}x',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
              ],
              if (resistances.isNotEmpty) ...[
                Text('Resists:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: resistances.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${t['type_name']} ${t['multiplier']}x',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
              ],
              if (immunities.isNotEmpty) ...[
                Text('Immune to:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: immunities.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${t['type_name']}',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovesCard() {
    if (_moveLearnset.isEmpty) return const SizedBox.shrink();

    List<Map<String, dynamic>> dedup(List<Map<String, dynamic>> moves) {
      final seen = <String>{};
      return moves.where((m) => seen.add(m['name']?.toString() ?? '')).toList();
    }

    final levelUp = dedup(_moveLearnset.where((m) => m['learn_method'] == 'level-up').toList());
    final tm = dedup(_moveLearnset.where((m) => m['learn_method'] == 'tm').toList());
    final egg = dedup(_moveLearnset.where((m) => m['learn_method'] == 'egg').toList());

    // Sort level-up by level
    levelUp.sort((a, b) {
      final aLevel = a['level_or_tm']?.toString() ?? '0';
      final bLevel = b['level_or_tm']?.toString() ?? '0';
      final aNum = int.tryParse(aLevel) ?? 0;
      final bNum = int.tryParse(bLevel) ?? 0;
      return aNum.compareTo(bNum);
    });

    Widget buildMoveSection(String title, List<Map<String, dynamic>> moves, IconData icon, Color color) {
      if (moves.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              const SizedBox(width: 4),
              Text('(${moves.length})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          ...moves.map((m) {
            final level = m['level_or_tm']?.toString() ?? '';
            final power = m['power'];
            final acc = m['accuracy'];
            final prefix = level.isNotEmpty && level != '\u2014' && level != 'null' ? 'Lv.$level ' : '';
            final suffix = power != null ? ' | Pow:$power' : '';
            final accStr = acc != null ? ' | Acc:$acc' : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '$prefix${m['name']} (${m['type']}, ${m['category']})$suffix$accStr',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Moves (${_moveLearnset.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildMoveSection('Level Up', levelUp, Icons.arrow_upward, Colors.blue.shade700),
                      buildMoveSection('TM/HM', tm, Icons.album, Colors.purple.shade700),
                      buildMoveSection('Egg Moves', egg, Icons.egg, Colors.orange.shade700),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlavorTextCard() {
    if (_flavorTextEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pokédex Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _flavorTextEntries.map((entry) {
                      final version = entry['version']?['name']?.toString() ?? '';
                      final text = entry['flavor_text']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                version,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade700),
                              ),
                            ),
                            Expanded(
                              child: Text(text, style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonNamesCard() {
    if (_pokemonNames.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Names in Other Languages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._pokemonNames.map((entry) {
                final language = entry['language']?.toString() ?? '';
                final name = entry['localized_name']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(language, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpritesCard() {
    if (_allSprites.isEmpty) return const SizedBox.shrink();

    // Group sprites by generation
    final Map<String, List<Map<String, dynamic>>> byGen = {};
    for (var sprite in _allSprites) {
      final gen = sprite['generation']?.toString() ?? 'Other';
      byGen.putIfAbsent(gen, () => []);
      byGen[gen]!.add(sprite);
    }

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sprite Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: byGen.entries.map((genEntry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(genEntry.key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade700)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: genEntry.value.map((sprite) {
                              final url = sprite['url']?.toString() ?? '';
                              final type = sprite['sprite_type']?.toString() ?? '';
                              if (url.isEmpty) return const SizedBox.shrink();
                              return Column(
                                children: [
                                  Image.network(
                                    url,
                                    width: 64,
                                    height: 64,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 32),
                                  ),
                                  Text(type, style: const TextStyle(fontSize: 9)),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiologyCard() {
    if (_biology.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Biology', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(_biology, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeldItemsCard() {
    if (_heldItems.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wild Held Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._heldItems.map((h) {
                final itemName = (h['item']?['name'] as String? ?? '').split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
                final game = h['game']?.toString() ?? '';
                final rarity = h['rarity']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.backpack, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(itemName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      if (rarity.isNotEmpty) Text(rarity, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (game.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(game, style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameLocationsCard() {
    if (_gameLocations.isEmpty) return const SizedBox.shrink();

    Color methodColor(String method) {
      switch (method) {
        case 'Special':  return Colors.purple;
        case 'Roaming':  return Colors.deepPurple;
        case 'Event':    return Colors.orange;
        case 'Gift':     return Colors.green;
        case 'Fossil':   return Colors.brown;
        case 'Trade':    return Colors.blue;
        case 'Hatch':    return Colors.pink;
        case 'Wild':     return Colors.grey.shade600;
        default:         return Colors.grey.shade600;
      }
    }

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How to Obtain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _gameLocations.map((loc) {
                      final game = loc['game']?.toString() ?? '';
                      final location = loc['location']?.toString() ?? '';
                      final method = loc['method']?.toString() ?? '';
                      final color = methodColor(method);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                border: Border.all(color: color, width: 1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                method.isEmpty ? 'Wild' : method,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(game, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                  Text(location, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvolutionNode(Map<String, dynamic> node, {bool showInfo = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showInfo &&
            node['info'] != null &&
            node['info'] != node['name'])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${node['info']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        if (node['img'] != null && node['img'] != '')
          Image.network(
            node['img'],
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error);
            },
          ),
        const SizedBox(height: 4),
        if (node['name'] != null)
          Text(
            '${node['name']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildEvolutionTree(Map<String, dynamic> node, {bool isRoot = true}) {
    final List<dynamic> evolvesTo = node['evolves_to'] ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEvolutionNode(node, showInfo: !isRoot),
        if (evolvesTo.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_downward),
          ),
          if (evolvesTo.length == 1)
            _buildEvolutionTree(evolvesTo[0] as Map<String, dynamic>, isRoot: false)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var child in evolvesTo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildEvolutionTree(child as Map<String, dynamic>, isRoot: false),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEvolutionCard() {
    final evolution = _pokemonData?['evolution'];
    final titles = _getSafeList('titles') as List;
    final bool noEvolution = evolution == null ||
        (evolution is Map && (evolution.isEmpty || (evolution['evolves_to'] as List?)?.isEmpty == true));

    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: <Widget>[
              if (titles.length > 4)
                Text(
                  '${titles[4]}\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (noEvolution)
                const Column(
                  children: <Widget>[
                    Text('This Pokémon does not evolve.'),
                  ],
                )
              else
                _buildEvolutionTree(evolution as Map<String, dynamic>),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        color: Colors.red,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      errorMessage = null;
                      isLoading = false;
                      _pokemonData = null;
                      _getPokemon().then((value) {
                        if (mounted) {
                          setState(() => names = value);
                        }
                      });
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _pokemonData == null
        ? Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.red,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Search for a Pokemon',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return names.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    }).take(10);
                  },
                  onSelected: (String selection) {
                    setState(() {
                      pokemon = selection;
                      isLoading = true;
                    });

                    _makeRequest(selection).then((data) {
                      if (mounted) {
                        setState(() {
                          _pokemonData = data;
                          isLoading = false;
                        });
                      }
                    }).catchError((error) {
                      if (mounted) {
                        setState(() {
                          errorMessage = 'Failed to load Pokemon: $error';
                          isLoading = false;
                        });
                      }
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter Pokemon name...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        suffixIcon: fieldTextEditingController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white),
                                onPressed: () {
                                  fieldTextEditingController.clear();
                                  setState(() {
                                    pokemon = null;
                                    _pokemonData = null;
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.red.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      onSubmitted: (String value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            pokemon = value;
                            isLoading = true;
                          });

                          _makeRequest(value).then((data) {
                            if (mounted) {
                              setState(() {
                                _pokemonData = data;
                                isLoading = false;
                              });
                            }
                          }).catchError((error) {
                            if (mounted) {
                              setState(() {
                                errorMessage = 'Failed to load Pokemon: $error';
                                isLoading = false;
                              });
                            }
                          });
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (
                    BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: const Color.fromRGBO(99, 118, 184, 1),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: options.length,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const CircularProgressIndicator(
                    color: Colors.red,
                  ),
              ],
            ),
          )
        : Container(
            height: MediaQuery.of(context).size.height - 130,
            color: Colors.red,
            child: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return Column(
                  children: <Widget>[
                    if (_getSafeData('image').isNotEmpty)
                      Container(
                        alignment: Alignment.topCenter,
                        width: double.infinity,
                        child: Image.network(
                          _getSafeData('image'),
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, size: 100);
                          },
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      width: double.infinity,
                      child: Card(
                        elevation: 10,
                        margin: const EdgeInsets.all(5),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: <Widget>[
                              if ((_getSafeList('titles') as List).isNotEmpty)
                                Text(
                                  '${(_getSafeList('titles') as List)[0]}\n',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Column(
                                children: <Widget>[
                                  Text(
                                    'National No: ${_getSafeData('data', 'Pokédex Data', 'National №')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Type: ${_getSafeData('data', 'Pokédex Data', 'Type')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Species: ${_getSafeData('data', 'Pokédex Data', 'Species')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Height: ${_getSafeData('data', 'Pokédex Data', 'Height')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Weight: ${_getSafeData('data', 'Pokédex Data', 'Weight')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Abilities: ${_getSafeData('data', 'Pokédex Data', 'Abilities')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      width: double.infinity,
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        elevation: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: <Widget>[
                              if ((_getSafeList('titles') as List).length > 1)
                                Text(
                                  '${(_getSafeList('titles') as List)[1]}\n',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Column(
                                children: <Widget>[
                                  Text(
                                    'EV yield: ${_getSafeData('data', 'Training', 'EV Yield')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Catch rate: ${_getSafeData('data', 'Training', 'Catch Rate')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Base Friendship: ${_getSafeData('data', 'Training', 'Base Friendship')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Base Exp.: ${_getSafeData('data', 'Training', 'Base Exp')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Growth Rate: ${_getSafeData('data', 'Training', 'Growth Rate')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      width: double.infinity,
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        elevation: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: <Widget>[
                              if ((_getSafeList('titles') as List).length > 2)
                                Text(
                                  '${(_getSafeList('titles') as List)[2]}\n',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              getEggs(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      width: double.infinity,
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        elevation: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: <Widget>[
                              if ((_getSafeList('titles') as List).length > 3)
                                Text(
                                  '${(_getSafeList('titles') as List)[3]}\n',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Column(
                                children: <Widget>[
                                  Text('HP: ${_getSafeData('data', 'Base Stats', 'HP')}'),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  Text('Attack: ${_getSafeData('data', 'Base Stats', 'Attack')}'),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  Text('Defense: ${_getSafeData('data', 'Base Stats', 'Defense')}'),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  Text('Sp. Atk: ${_getSafeData('data', 'Base Stats', 'Sp. Atk')}'),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  Text('Sp. Def: ${_getSafeData('data', 'Base Stats', 'Sp. Def')}'),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  Text('Speed: ${_getSafeData('data', 'Base Stats', 'Speed')}'),
                                  const Padding(padding: EdgeInsets.all(5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFlavorTextCard(),
                    _buildTypeDefensesCard(),
                    _buildRecommendedNatureCard(),
                    _buildMovesCard(),
                    _buildEvolutionCard(),
                    _buildPokemonNamesCard(),
                    _buildBiologyCard(),
                    _buildHeldItemsCard(),
                    _buildGameLocationsCard(),
                    _buildSpritesCard(),
                    if (pokemonLocations.isNotEmpty &&
                        pokemonLocations[0] != 'No location data available')
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: double.infinity,
                        child: Card(
                          margin: const EdgeInsets.all(5),
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Encounter Locations\n',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                getPokemonWidget(),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
  }
}
