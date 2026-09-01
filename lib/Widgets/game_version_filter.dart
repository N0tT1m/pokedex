import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';
import '../services/pokemondb_service.dart';

/// Widget for browsing the Pokedex by game version
class GameVersionFilter extends StatefulWidget {
  const GameVersionFilter({Key? key}) : super(key: key);

  @override
  State<GameVersionFilter> createState() => _GameVersionFilterState();
}

class _GameVersionFilterState extends State<GameVersionFilter>
    with TickerProviderStateMixin {
  // Current view state
  String? _selectedVersionKey;
  String? _selectedVersionName;
  int? _selectedNationalDexMax;
  Map<String, List<Map<String, dynamic>>> _pokedexGroups = {};
  List<String> _pokedexNames = [];
  int _selectedPokedexIndex = 0;
  bool _isLoadingPokedex = false;
  String? _errorMessage;

  // Pokemon detail state
  Map<String, dynamic>? _selectedPokemonData;
  bool _isLoadingDetail = false;
  List<String> _pokemonLocations = [];
  List<Map<String, dynamic>> _typeDefenses = [];
  List<Map<String, dynamic>> _moveLearnset = [];

  // Tab controller for pokedex switching
  TabController? _tabController;

  // Available game versions grouped by generation
  final List<Map<String, dynamic>> _gameGroups = [
    {
      'generation': 'Generation I',
      'games': [
        {'key': 'red-blue', 'name': 'Red / Blue', 'color': Colors.red, 'nationalDexMax': 151},
        {'key': 'yellow', 'name': 'Yellow', 'color': Colors.amber, 'nationalDexMax': 151},
      ],
    },
    {
      'generation': 'Generation II',
      'games': [
        {'key': 'gold-silver', 'name': 'Gold / Silver', 'color': Colors.orange, 'nationalDexMax': 251},
        {'key': 'crystal', 'name': 'Crystal', 'color': Colors.cyan, 'nationalDexMax': 251},
      ],
    },
    {
      'generation': 'Generation III',
      'games': [
        {'key': 'ruby-sapphire', 'name': 'Ruby / Sapphire', 'color': Colors.redAccent, 'nationalDexMax': 386},
        {'key': 'emerald', 'name': 'Emerald', 'color': Colors.green, 'nationalDexMax': 386},
        {'key': 'firered-leafgreen', 'name': 'FireRed / LeafGreen', 'color': Colors.deepOrange, 'nationalDexMax': 386},
      ],
    },
    {
      'generation': 'Generation IV',
      'games': [
        {'key': 'diamond-pearl', 'name': 'Diamond / Pearl', 'color': Colors.blueAccent, 'nationalDexMax': 493},
        {'key': 'platinum', 'name': 'Platinum', 'color': Colors.grey, 'nationalDexMax': 493},
        {'key': 'heartgold-soulsilver', 'name': 'HeartGold / SoulSilver', 'color': Colors.amber, 'nationalDexMax': 493},
      ],
    },
    {
      'generation': 'Generation V',
      'games': [
        {'key': 'black-white', 'name': 'Black / White', 'color': Colors.blueGrey, 'nationalDexMax': 649},
        {'key': 'black-2-white-2', 'name': 'Black 2 / White 2', 'color': Colors.blueGrey, 'nationalDexMax': 649},
      ],
    },
    {
      'generation': 'Generation VI',
      'games': [
        {'key': 'x-y', 'name': 'X / Y', 'color': Colors.indigo, 'nationalDexMax': 721},
        {'key': 'omega-ruby-alpha-sapphire', 'name': 'Omega Ruby / Alpha Sapphire', 'color': Colors.redAccent, 'nationalDexMax': 721},
      ],
    },
    {
      'generation': 'Generation VII',
      'games': [
        {'key': 'sun-moon', 'name': 'Sun / Moon', 'color': Colors.orange, 'nationalDexMax': 802},
        {'key': 'ultra-sun-ultra-moon', 'name': 'Ultra Sun / Ultra Moon', 'color': Colors.deepOrange, 'nationalDexMax': 807},
        {'key': 'lets-go-pikachu-lets-go-eevee', 'name': "Let's Go Pikachu / Eevee", 'color': Colors.yellow, 'nationalDexMax': 809},
      ],
    },
    {
      'generation': 'Generation VIII',
      'games': [
        {'key': 'sword-shield', 'name': 'Sword / Shield', 'color': Colors.blue, 'nationalDexMax': 898},
        {'key': 'brilliant-diamond-shining-pearl', 'name': 'Brilliant Diamond / Shining Pearl', 'color': Colors.lightBlue, 'nationalDexMax': 493},
        {'key': 'legends-arceus', 'name': 'Legends: Arceus', 'color': Colors.teal, 'nationalDexMax': 905},
      ],
    },
    {
      'generation': 'Generation IX',
      'games': [
        {'key': 'scarlet-violet', 'name': 'Scarlet / Violet', 'color': Colors.deepPurple, 'nationalDexMax': 1025},
        {'key': 'the-teal-mask', 'name': 'The Teal Mask (DLC)', 'color': Colors.teal, 'nationalDexMax': 1025},
        {'key': 'the-indigo-disk', 'name': 'The Indigo Disk (DLC)', 'color': Colors.indigo, 'nationalDexMax': 1025},
      ],
    },
  ];

  Future<void> _loadGamePokedex(String versionKey, String versionName, {int? nationalDexMax}) async {
    setState(() {
      _selectedVersionKey = versionKey;
      _selectedVersionName = versionName;
      _selectedNationalDexMax = nationalDexMax;
      _isLoadingPokedex = true;
      _errorMessage = null;
      _pokedexGroups = {};
      _pokedexNames = [];
      _selectedPokedexIndex = 0;
      _selectedPokemonData = null;
      _tabController?.dispose();
      _tabController = null;
    });

    try {
      final versionData = await PokeApiService.getVersionGroup(versionKey);
      final List<dynamic> pokedexes = versionData['pokedexes'] ?? [];

      Map<String, List<Map<String, dynamic>>> groups = {};
      List<String> names = [];
      bool hasNational = false;

      for (var pokedexRef in pokedexes) {
        final pokedexUrl = pokedexRef['url'];
        final pokedexName = pokedexRef['name'];
        final pokedexId = PokeApiService.extractIdFromUrl(pokedexUrl);

        if (pokedexId != null) {
          final isNational = pokedexId == 1 || pokedexName == 'national';
          if (isNational) {
            hasNational = true;
          }

          final pokedexData = await PokeApiService.getPokedex(pokedexId);
          final List<dynamic> pokemonSpecies = pokedexData['pokemon_entries'] ?? [];
          final dexName = PokemonDataFormatter.capitalize(
            (pokedexData['name'] ?? pokedexName ?? 'Unknown').toString().replaceAll('-', ' '),
          );

          List<Map<String, dynamic>> entries = [];
          for (var entry in pokemonSpecies) {
            final entryNumber = entry['entry_number'];
            // Filter national dex by generation limit if applicable
            if (isNational && nationalDexMax != null && entryNumber is int && entryNumber > nationalDexMax) {
              continue;
            }
            final speciesName = entry['pokemon_species']['name'];
            final speciesUrl = entry['pokemon_species']['url'];
            final speciesId = PokeApiService.extractIdFromUrl(speciesUrl);

            entries.add({
              'entry_number': entryNumber,
              'name': PokemonDataFormatter.capitalize(speciesName),
              'api_name': speciesName,
              'id': speciesId ?? 0,
              'dex_name': dexName,
              'image': speciesId != null
                  ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$speciesId.png'
                  : '',
            });
          }

          entries.sort((a, b) => (a['entry_number'] as int).compareTo(b['entry_number'] as int));
          names.add(dexName);
          groups[dexName] = entries;
        }
      }

      // Add filtered national dex if none was provided by the API
      if (!hasNational && nationalDexMax != null) {
        final nationalData = await PokeApiService.getPokedex(1);
        final List<dynamic> nationalSpecies = nationalData['pokemon_entries'] ?? [];

        List<Map<String, dynamic>> nationalEntries = [];
        for (var entry in nationalSpecies) {
          final entryNumber = entry['entry_number'] as int;
          if (entryNumber > nationalDexMax) continue;

          final speciesName = entry['pokemon_species']['name'];
          final speciesUrl = entry['pokemon_species']['url'];
          final speciesId = PokeApiService.extractIdFromUrl(speciesUrl);

          nationalEntries.add({
            'entry_number': entryNumber,
            'name': PokemonDataFormatter.capitalize(speciesName),
            'api_name': speciesName,
            'id': speciesId ?? 0,
            'dex_name': 'National',
            'image': speciesId != null
                ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$speciesId.png'
                : '',
          });
        }

        nationalEntries.sort((a, b) => (a['entry_number'] as int).compareTo(b['entry_number'] as int));
        names.add('National');
        groups['National'] = nationalEntries;
      }

      if (mounted) {
        _tabController = TabController(length: names.length, vsync: this);
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            setState(() {
              _selectedPokedexIndex = _tabController!.index;
            });
          }
        });
        setState(() {
          _pokedexGroups = groups;
          _pokedexNames = names;
          _selectedPokedexIndex = 0;
          _isLoadingPokedex = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load Pokedex: $e';
          _isLoadingPokedex = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadPokemonDetail(String apiName) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedPokemonData = null;
      _pokemonLocations = [];
      _typeDefenses = [];
      _moveLearnset = [];
    });

    try {
      final pokemonData = await PokeApiService.getPokemon(apiName);
      final speciesData = await PokeApiService.getPokemonSpecies(apiName);

      Map<String, dynamic>? evolutionData;
      final evolutionChainUrl = speciesData['evolution_chain']?['url'];
      if (evolutionChainUrl != null) {
        final evolutionId = PokeApiService.extractIdFromUrl(evolutionChainUrl);
        if (evolutionId != null) {
          evolutionData = await PokeApiService.getEvolutionChain(evolutionId);
        }
      }

      final formattedData = await PokemonDataFormatter.formatPokemonData(
        pokemonData,
        speciesData,
        evolutionData,
      );

      // Fetch type defenses and moves
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

      // Fetch encounter locations
      try {
        final encounterData = await PokemonDBService.getEncounterLocations(apiName);
        List<String> locations = [];
        for (var entry in encounterData.entries) {
          if (entry.value.isNotEmpty) {
            locations.add('${entry.key}: ${entry.value.join(', ')}');
          }
        }
        if (locations.isEmpty) {
          locations.add('No location data available');
        }
        _pokemonLocations = locations;
      } catch (e) {
        _pokemonLocations = ['Unable to load location data'];
      }

      formattedData['locations'] = _pokemonLocations;

      if (mounted) {
        setState(() {
          _selectedPokemonData = formattedData;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
          _errorMessage = 'Failed to load Pokemon details: $e';
        });
      }
    }
  }

  void _goBack() {
    setState(() {
      if (_selectedPokemonData != null) {
        _selectedPokemonData = null;
      } else {
        _selectedVersionKey = null;
        _selectedVersionName = null;
        _pokedexGroups = {};
        _pokedexNames = [];
        _tabController?.dispose();
        _tabController = null;
      }
    });
  }

  String _getSafeData(String key1, [String? key2, String? key3]) {
    if (_selectedPokemonData == null) return 'N/A';
    try {
      if (key2 == null) {
        return _selectedPokemonData![key1]?.toString() ?? 'N/A';
      } else if (key3 == null) {
        return _selectedPokemonData![key1]?[key2]?.toString() ?? 'N/A';
      } else {
        return _selectedPokemonData![key1]?[key2]?[key3]?.toString() ?? 'N/A';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  dynamic _getSafeList(String key) {
    if (_selectedPokemonData == null) return [];
    return _selectedPokemonData![key] ?? [];
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
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.red,
          child: Row(
            children: [
              if (_selectedVersionKey != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_selectedVersionKey != null) const SizedBox(width: 8),
              const Icon(Icons.videogame_asset, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedPokemonData != null
                      ? _getSafeData('name')
                      : _selectedVersionName ?? 'Game Pokedex',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_selectedVersionKey != null && _selectedPokemonData == null && _pokedexNames.isNotEmpty)
                Text(
                  '${_pokedexNames.length} ${_pokedexNames.length == 1 ? "Dex" : "Dexes"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _selectedPokemonData != null
              ? _buildPokemonDetail()
              : _selectedVersionKey != null
                  ? _buildPokedexList()
                  : _buildGameSelector(),
        ),
      ],
    );
  }

  // --- Game Selector Screen ---
  Widget _buildGameSelector() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _gameGroups.length,
      itemBuilder: (context, index) {
        final group = _gameGroups[index];
        final games = group['games'] as List<Map<String, dynamic>>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                group['generation'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF616161),
                ),
              ),
            ),
            ...games.map((game) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.catching_pokemon,
                    color: game['color'] as Color,
                    size: 32,
                  ),
                  title: Text(
                    game['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadGamePokedex(game['key'], game['name'], nationalDexMax: game['nationalDexMax'] as int?),
                ),
              );
            }),
            if (index < _gameGroups.length - 1) const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // --- Pokedex List Screen ---
  Widget _buildPokedexList() {
    if (_isLoadingPokedex) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Loading Pokedex...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadGamePokedex(_selectedVersionKey!, _selectedVersionName!, nationalDexMax: _selectedNationalDexMax),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pokedexNames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Pokedex data available for this game', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pokedex tab bar
        if (_pokedexNames.length > 1 && _tabController != null)
          Material(
            color: Colors.red.shade700,
            child: TabBar(
              controller: _tabController,
              isScrollable: _pokedexNames.length > 3,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: _pokedexNames.map((name) {
                final count = _pokedexGroups[name]?.length ?? 0;
                return Tab(text: '$name ($count)');
              }).toList(),
            ),
          ),
        // Pokemon count summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.catching_pokemon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${_currentEntries.length} Pokemon',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // Pokemon list
        Expanded(
          child: _pokedexNames.length > 1 && _tabController != null
              ? TabBarView(
                  controller: _tabController,
                  children: _pokedexNames.map((name) {
                    final entries = _pokedexGroups[name] ?? [];
                    return _buildEntryList(entries);
                  }).toList(),
                )
              : _buildEntryList(_currentEntries),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get _currentEntries {
    if (_pokedexNames.isEmpty) return [];
    final name = _pokedexNames[_selectedPokedexIndex];
    return _pokedexGroups[name] ?? [];
  }

  Widget _buildEntryList(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No Pokemon in this Pokedex', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isNational = entry['dex_name'] == 'National';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            leading: SizedBox(
              width: 56,
              height: 56,
              child: Image.network(
                entry['image'],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.catching_pokemon, size: 40);
                },
              ),
            ),
            title: Text(
              entry['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isNational
                  ? 'National #${entry['entry_number'].toString().padLeft(4, '0')}'
                  : '#${entry['entry_number'].toString().padLeft(3, '0')}  (National #${entry['id'].toString().padLeft(4, '0')})',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadPokemonDetail(entry['api_name']),
          ),
        );
      },
    );
  }

  // --- Pokemon Detail Screen ---
  Widget _buildPokemonDetail() {
    if (_isLoadingDetail) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Loading Pokemon...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_selectedPokemonData == null) return const SizedBox.shrink();

    final titles = _getSafeList('titles') as List;
    final evolution = _selectedPokemonData?['evolution'];

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Pokemon Image
        if (_getSafeData('image').isNotEmpty)
          Container(
            alignment: Alignment.topCenter,
            width: double.infinity,
            child: Image.network(
              _getSafeData('image'),
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 100);
              },
            ),
          ),

        // Flavor text
        if (_getSafeData('flavorText') != 'N/A')
          Card(
            margin: const EdgeInsets.all(5),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _getSafeData('flavorText'),
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Pokedex Data
        _buildDataCard(
          titles.isNotEmpty ? titles[0] : 'Pokedex Data',
          [
            'National No: ${_getSafeData('data', 'Pokédex Data', 'National №')}',
            'Type: ${_getSafeData('data', 'Pokédex Data', 'Type')}',
            'Species: ${_getSafeData('data', 'Pokédex Data', 'Species')}',
            'Height: ${_getSafeData('data', 'Pokédex Data', 'Height')}',
            'Weight: ${_getSafeData('data', 'Pokédex Data', 'Weight')}',
            'Abilities: ${_getSafeData('data', 'Pokédex Data', 'Abilities')}',
          ],
        ),

        // Training
        _buildDataCard(
          titles.length > 1 ? titles[1] : 'Training',
          [
            'EV yield: ${_getSafeData('data', 'Training', 'EV Yield')}',
            'Catch rate: ${_getSafeData('data', 'Training', 'Catch Rate')}',
            'Base Friendship: ${_getSafeData('data', 'Training', 'Base Friendship')}',
            'Base Exp.: ${_getSafeData('data', 'Training', 'Base Exp')}',
            'Growth Rate: ${_getSafeData('data', 'Training', 'Growth Rate')}',
          ],
        ),

        // Breeding
        _buildDataCard(
          titles.length > 2 ? titles[2] : 'Breeding',
          [
            'Egg Groups: ${_getSafeData('data', 'Breeding', 'Egg Groups')}',
            'Gender: ${_getSafeData('data', 'Breeding', 'Gender')}',
            'Egg Cycles: ${_getSafeData('data', 'Breeding', 'Egg Cycles')}',
          ],
        ),

        // Base Stats
        _buildDataCard(
          titles.length > 3 ? titles[3] : 'Base Stats',
          [
            'HP: ${_getSafeData('data', 'Base Stats', 'HP')}',
            'Attack: ${_getSafeData('data', 'Base Stats', 'Attack')}',
            'Defense: ${_getSafeData('data', 'Base Stats', 'Defense')}',
            'Sp. Atk: ${_getSafeData('data', 'Base Stats', 'Sp. Atk')}',
            'Sp. Def: ${_getSafeData('data', 'Base Stats', 'Sp. Def')}',
            'Speed: ${_getSafeData('data', 'Base Stats', 'Speed')}',
          ],
        ),

        // Type Defenses
        if (_typeDefenses.isNotEmpty)
          _buildTypeDefensesSection(),

        // Moves
        if (_moveLearnset.isNotEmpty)
          _buildMovesSection(),

        // Evolution
        Container(
          padding: const EdgeInsets.all(5),
          width: double.infinity,
          child: Card(
            margin: const EdgeInsets.all(5),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    titles.length > 4 ? '${titles[4]}' : 'Evolution',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (evolution == null ||
                      (evolution is Map && (evolution.isEmpty || (evolution['evolves_to'] as List?)?.isEmpty == true)))
                    const Text('This Pokemon does not evolve.')
                  else
                    _buildEvolutionTree(evolution as Map<String, dynamic>),
                ],
              ),
            ),
          ),
        ),

        // Locations
        if (_pokemonLocations.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(5),
            width: double.infinity,
            child: Card(
              margin: const EdgeInsets.all(5),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Locations',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (var location in _pokemonLocations) ...[
                      Text(location, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeDefensesSection() {
    final weaknesses = _typeDefenses.where((t) => (t['multiplier'] as num) > 1).toList();
    final resistances = _typeDefenses.where((t) => (t['multiplier'] as num) < 1 && (t['multiplier'] as num) > 0).toList();
    final immunities = _typeDefenses.where((t) => (t['multiplier'] as num) == 0).toList();

    Widget buildRow(String label, List<Map<String, dynamic>> items, Color bgColor, Color textColor, {bool showMultiplier = true}) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: items.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Text(
                showMultiplier ? '${t['type_name']} ${t['multiplier']}x' : '${t['type_name']}',
                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type Defenses', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              buildRow('Weak to:', weaknesses, Colors.red.shade100, Colors.red.shade800),
              buildRow('Resists:', resistances, Colors.green.shade100, Colors.green.shade800),
              buildRow('Immune to:', immunities, Colors.blue.shade100, Colors.blue.shade800, showMultiplier: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovesSection() {
    List<Map<String, dynamic>> dedup(List<Map<String, dynamic>> moves) {
      final seen = <String>{};
      return moves.where((m) => seen.add(m['name']?.toString() ?? '')).toList();
    }

    final levelUp = dedup(_moveLearnset.where((m) => m['learn_method'] == 'level-up').toList());
    final tm = dedup(_moveLearnset.where((m) => m['learn_method'] == 'tm').toList());
    final egg = dedup(_moveLearnset.where((m) => m['learn_method'] == 'egg').toList());

    levelUp.sort((a, b) {
      final aNum = int.tryParse(a['level_or_tm']?.toString() ?? '0') ?? 0;
      final bNum = int.tryParse(b['level_or_tm']?.toString() ?? '0') ?? 0;
      return aNum.compareTo(bNum);
    });

    Widget buildSection(String title, List<Map<String, dynamic>> moves, IconData icon, Color color) {
      if (moves.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text('$title (${moves.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ]),
          const SizedBox(height: 4),
          ...moves.map((m) {
            final level = m['level_or_tm']?.toString() ?? '';
            final power = m['power'];
            final prefix = level.isNotEmpty && level != '\u2014' && level != 'null' ? 'Lv.$level ' : '';
            final suffix = power != null ? ' | Pow:$power' : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('$prefix${m['name']} (${m['type']}, ${m['category']})$suffix', style: const TextStyle(fontSize: 12)),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Moves (${_moveLearnset.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSection('Level Up', levelUp, Icons.arrow_upward, Colors.blue.shade700),
                      buildSection('TM/HM', tm, Icons.album, Colors.purple.shade700),
                      buildSection('Egg Moves', egg, Icons.egg, Colors.orange.shade700),
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

  Widget _buildDataCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(5),
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.all(5),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (var item in items) ...[
                Text(item),
                const SizedBox(height: 5),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
