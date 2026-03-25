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

class _GameVersionFilterState extends State<GameVersionFilter> {
  // Current view state
  String? _selectedVersionKey;
  String? _selectedVersionName;
  List<Map<String, dynamic>> _pokedexEntries = [];
  bool _isLoadingPokedex = false;
  String? _errorMessage;

  // Pokemon detail state
  Map<String, dynamic>? _selectedPokemonData;
  bool _isLoadingDetail = false;
  List<String> _pokemonLocations = [];

  // Available game versions grouped by generation
  final List<Map<String, dynamic>> _gameGroups = [
    {
      'generation': 'Generation I',
      'games': [
        {'key': 'red-blue', 'name': 'Red / Blue', 'color': Colors.red},
        {'key': 'yellow', 'name': 'Yellow', 'color': Colors.amber},
      ],
    },
    {
      'generation': 'Generation II',
      'games': [
        {'key': 'gold-silver', 'name': 'Gold / Silver', 'color': Colors.orange},
        {'key': 'crystal', 'name': 'Crystal', 'color': Colors.cyan},
      ],
    },
    {
      'generation': 'Generation III',
      'games': [
        {'key': 'ruby-sapphire', 'name': 'Ruby / Sapphire', 'color': Colors.redAccent},
        {'key': 'emerald', 'name': 'Emerald', 'color': Colors.green},
        {'key': 'firered-leafgreen', 'name': 'FireRed / LeafGreen', 'color': Colors.deepOrange},
      ],
    },
    {
      'generation': 'Generation IV',
      'games': [
        {'key': 'diamond-pearl', 'name': 'Diamond / Pearl', 'color': Colors.blueAccent},
        {'key': 'platinum', 'name': 'Platinum', 'color': Colors.grey},
        {'key': 'heartgold-soulsilver', 'name': 'HeartGold / SoulSilver', 'color': Colors.amber},
      ],
    },
    {
      'generation': 'Generation V',
      'games': [
        {'key': 'black-white', 'name': 'Black / White', 'color': Colors.blueGrey},
        {'key': 'black-2-white-2', 'name': 'Black 2 / White 2', 'color': Colors.blueGrey},
      ],
    },
    {
      'generation': 'Generation VI',
      'games': [
        {'key': 'x-y', 'name': 'X / Y', 'color': Colors.indigo},
        {'key': 'omega-ruby-alpha-sapphire', 'name': 'Omega Ruby / Alpha Sapphire', 'color': Colors.redAccent},
      ],
    },
    {
      'generation': 'Generation VII',
      'games': [
        {'key': 'sun-moon', 'name': 'Sun / Moon', 'color': Colors.orange},
        {'key': 'ultra-sun-ultra-moon', 'name': 'Ultra Sun / Ultra Moon', 'color': Colors.deepOrange},
        {'key': 'lets-go-pikachu-lets-go-eevee', 'name': "Let's Go Pikachu / Eevee", 'color': Colors.yellow},
      ],
    },
    {
      'generation': 'Generation VIII',
      'games': [
        {'key': 'sword-shield', 'name': 'Sword / Shield', 'color': Colors.blue},
        {'key': 'brilliant-diamond-shining-pearl', 'name': 'Brilliant Diamond / Shining Pearl', 'color': Colors.lightBlue},
        {'key': 'legends-arceus', 'name': 'Legends: Arceus', 'color': Colors.teal},
      ],
    },
    {
      'generation': 'Generation IX',
      'games': [
        {'key': 'scarlet-violet', 'name': 'Scarlet / Violet', 'color': Colors.deepPurple},
        {'key': 'the-teal-mask', 'name': 'The Teal Mask (DLC)', 'color': Colors.teal},
        {'key': 'the-indigo-disk', 'name': 'The Indigo Disk (DLC)', 'color': Colors.indigo},
      ],
    },
  ];

  Future<void> _loadGamePokedex(String versionKey, String versionName) async {
    setState(() {
      _selectedVersionKey = versionKey;
      _selectedVersionName = versionName;
      _isLoadingPokedex = true;
      _errorMessage = null;
      _pokedexEntries = [];
      _selectedPokemonData = null;
    });

    try {
      final versionData = await PokeApiService.getVersionGroup(versionKey);
      final List<dynamic> pokedexes = versionData['pokedexes'] ?? [];

      List<Map<String, dynamic>> allEntries = [];

      for (var pokedexRef in pokedexes) {
        final pokedexUrl = pokedexRef['url'];
        final pokedexName = pokedexRef['name'];
        final pokedexId = PokeApiService.extractIdFromUrl(pokedexUrl);

        if (pokedexId != null) {
          final pokedexData = await PokeApiService.getPokedex(pokedexId);
          final List<dynamic> pokemonSpecies = pokedexData['pokemon_entries'] ?? [];
          final dexName = PokemonDataFormatter.capitalize(
            (pokedexData['name'] ?? pokedexName ?? 'Unknown').toString().replaceAll('-', ' '),
          );

          for (var entry in pokemonSpecies) {
            final entryNumber = entry['entry_number'];
            final speciesName = entry['pokemon_species']['name'];
            final speciesUrl = entry['pokemon_species']['url'];
            final speciesId = PokeApiService.extractIdFromUrl(speciesUrl);

            allEntries.add({
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
        }
      }

      // Sort by entry number
      allEntries.sort((a, b) => (a['entry_number'] as int).compareTo(b['entry_number'] as int));

      if (mounted) {
        setState(() {
          _pokedexEntries = allEntries;
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

  Future<void> _loadPokemonDetail(String apiName) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedPokemonData = null;
      _pokemonLocations = [];
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
        _pokedexEntries = [];
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
              if (_selectedVersionKey != null && _selectedPokemonData == null)
                Text(
                  '${_pokedexEntries.length} Pokemon',
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
                  color: Colors.grey.shade700,
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
                  onTap: () => _loadGamePokedex(game['key'], game['name']),
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
              onPressed: () => _loadGamePokedex(_selectedVersionKey!, _selectedVersionName!),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pokedexEntries.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _pokedexEntries.length,
      itemBuilder: (context, index) {
        final entry = _pokedexEntries[index];
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
              '#${entry['entry_number'].toString().padLeft(3, '0')}  (National #${entry['id'].toString().padLeft(4, '0')})',
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
    final evolutions = _getSafeList('evolution') as List;

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
                  if (evolutions.isEmpty || evolutions.length == 1)
                    const Text('This Pokemon does not evolve.')
                  else
                    Column(
                      children: [
                        for (int i = 0; i < evolutions.length; i++) ...[
                          if (evolutions[i]['img'] != null)
                            Image.network(
                              evolutions[i]['img'],
                              height: 80,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                            ),
                          const SizedBox(height: 4),
                          if (evolutions[i]['name'] != null)
                            Text(
                              '${evolutions[i]['name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          if (evolutions[i]['info'] != null &&
                              evolutions[i]['info'] != evolutions[i]['name'])
                            Text('${evolutions[i]['info']}'),
                          if (i < evolutions.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Icon(Icons.arrow_downward),
                            ),
                        ],
                      ],
                    ),
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
