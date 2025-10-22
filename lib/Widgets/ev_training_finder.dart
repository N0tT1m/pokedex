import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';

/// Widget for finding Pokemon by EV yields and game version
class EVTrainingFinder extends StatefulWidget {
  const EVTrainingFinder({Key? key}) : super(key: key);

  @override
  State<EVTrainingFinder> createState() => _EVTrainingFinderState();
}

class _EVTrainingFinderState extends State<EVTrainingFinder> {
  List<Map<String, dynamic>> pokemonList = [];
  List<Map<String, dynamic>> filteredPokemonList = [];
  bool isLoading = true;
  bool isFiltering = false;
  String? errorMessage;

  // Available game versions
  final Map<String, String> gameVersions = {
    'red-blue': 'Red/Blue',
    'yellow': 'Yellow',
    'gold-silver': 'Gold/Silver',
    'crystal': 'Crystal',
    'ruby-sapphire': 'Ruby/Sapphire',
    'emerald': 'Emerald',
    'firered-leafgreen': 'FireRed/LeafGreen',
    'diamond-pearl': 'Diamond/Pearl',
    'platinum': 'Platinum',
    'heartgold-soulsilver': 'HeartGold/SoulSilver',
    'black-white': 'Black/White',
    'black-2-white-2': 'Black 2/White 2',
    'x-y': 'X/Y',
    'omega-ruby-alpha-sapphire': 'Omega Ruby/Alpha Sapphire',
    'sun-moon': 'Sun/Moon',
    'ultra-sun-ultra-moon': 'Ultra Sun/Ultra Moon',
    'lets-go-pikachu-lets-go-eevee': 'Let\'s Go Pikachu/Eevee',
    'sword-shield': 'Sword/Shield',
    'brilliant-diamond-and-shining-pearl': 'Brilliant Diamond/Shining Pearl',
    'legends-arceus': 'Legends: Arceus',
    'scarlet-violet': 'Scarlet/Violet',
  };

  // EV stat types
  final Map<String, String> evStats = {
    'HP': 'HP',
    'Attack': 'Attack',
    'Defense': 'Defense',
    'Sp. Atk': 'Sp. Atk',
    'Sp. Def': 'Sp. Def',
    'Speed': 'Speed',
  };

  final Map<String, Color> evStatColors = {
    'HP': Colors.red,
    'Attack': Colors.orange,
    'Defense': Colors.blue,
    'Sp. Atk': Colors.purple,
    'Sp. Def': Colors.green,
    'Speed': Colors.yellow,
  };

  Set<String> selectedVersions = {};
  Set<String> selectedEVStats = {};

  @override
  void initState() {
    super.initState();
    _loadAllPokemon();
  }

  Future<void> _loadAllPokemon() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final pokemonListData = await PokeApiService.getPokemonList(limit: 1025);
      final List<Map<String, dynamic>> formattedPokemon = [];

      // Load first 200 Pokemon with full data (including EV yields)
      final int detailedLoadCount = 200;

      for (int i = 0; i < pokemonListData.length; i++) {
        final pokemonId = PokeApiService.extractIdFromUrl(pokemonListData[i]['url']) ?? (i + 1);
        final pokemonName = pokemonListData[i]['name'];

        Map<String, dynamic> pokemonData = {
          'id': pokemonId,
          'name': PokemonDataFormatter.capitalize(pokemonName),
          'types': [],
          'image': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png',
          'evYields': <String, int>{},
        };

        // Load full data for first batch to get EV yields
        if (i < detailedLoadCount) {
          try {
            final detailedData = await PokeApiService.getPokemon(pokemonName);
            pokemonData['evYields'] = _extractEVYields(detailedData);
          } catch (e) {
            print('Error loading details for $pokemonName: $e');
          }
        }

        formattedPokemon.add(pokemonData);
      }

      if (mounted) {
        setState(() {
          pokemonList = formattedPokemon;
          filteredPokemonList = formattedPokemon;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading Pokemon: $e';
          isLoading = false;
        });
      }
    }
  }

  Map<String, int> _extractEVYields(Map<String, dynamic> pokemonData) {
    final Map<String, int> evYields = {};
    final statMap = {
      'hp': 'HP',
      'attack': 'Attack',
      'defense': 'Defense',
      'special-attack': 'Sp. Atk',
      'special-defense': 'Sp. Def',
      'speed': 'Speed',
    };

    final stats = pokemonData['stats'] as List;
    for (var stat in stats) {
      final statName = stat['stat']['name'];
      final effort = stat['effort'] as int;
      final mappedName = statMap[statName];
      if (mappedName != null && effort > 0) {
        evYields[mappedName] = effort;
      }
    }

    return evYields;
  }

  Future<void> _applyFilter() async {
    if (selectedVersions.isEmpty && selectedEVStats.isEmpty) {
      setState(() {
        filteredPokemonList = pokemonList;
      });
      return;
    }

    setState(() {
      isFiltering = true;
    });

    try {
      Set<int>? availablePokemonIds;

      // Filter by game version if selected
      if (selectedVersions.isNotEmpty) {
        availablePokemonIds = {};
        for (String version in selectedVersions) {
          final versionData = await PokeApiService.getVersionGroup(version);
          final List<dynamic> pokemonEntries = versionData['pokedexes'] ?? [];

          for (var pokedexEntry in pokemonEntries) {
            final pokedexUrl = pokedexEntry['url'];
            final pokedexId = PokeApiService.extractIdFromUrl(pokedexUrl);
            if (pokedexId != null) {
              final pokedexData = await PokeApiService.getPokedex(pokedexId);
              final List<dynamic> pokemonSpecies = pokedexData['pokemon_entries'] ?? [];

              for (var entry in pokemonSpecies) {
                final speciesUrl = entry['pokemon_species']['url'];
                final pokemonId = PokeApiService.extractIdFromUrl(speciesUrl);
                if (pokemonId != null) {
                  availablePokemonIds.add(pokemonId);
                }
              }
            }
          }
        }
      }

      // Filter the pokemon list
      var filtered = pokemonList.where((pokemon) {
        // Filter by game version
        if (availablePokemonIds != null && !availablePokemonIds.contains(pokemon['id'])) {
          return false;
        }

        // Filter by EV yields
        if (selectedEVStats.isNotEmpty) {
          final evYields = pokemon['evYields'] as Map<String, int>;

          // Check if this Pokemon gives EVs for any of the selected stats
          bool hasSelectedEV = false;
          for (String stat in selectedEVStats) {
            if (evYields.containsKey(stat) && evYields[stat]! > 0) {
              hasSelectedEV = true;
              break;
            }
          }

          if (!hasSelectedEV) {
            return false;
          }
        }

        return true;
      }).toList();

      // Load detailed data for filtered Pokemon if not already loaded
      for (var pokemon in filtered) {
        if ((pokemon['evYields'] as Map<String, int>).isEmpty) {
          try {
            final pokemonName = pokemon['name'].toString().toLowerCase();
            final detailedData = await PokeApiService.getPokemon(pokemonName);
            pokemon['evYields'] = _extractEVYields(detailedData);
          } catch (e) {
            print('Error loading EV data for ${pokemon['name']}: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          filteredPokemonList = filtered;
          isFiltering = false;
        });
      }
    } catch (e) {
      print('Error filtering Pokemon: $e');
      if (mounted) {
        setState(() {
          isFiltering = false;
          errorMessage = 'Error applying filter: $e';
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedVersions.clear();
      selectedEVStats.clear();
      filteredPokemonList = pokemonList;
    });
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
              const Icon(Icons.fitness_center, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'EV Training Finder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (selectedVersions.isNotEmpty || selectedEVStats.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  onPressed: _clearFilters,
                  tooltip: 'Clear all filters',
                ),
            ],
          ),
        ),

        // Filters container
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EV Stat Filter Section
                Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select EV Stat to Train:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: evStats.entries.map((entry) {
                          final isSelected = selectedEVStats.contains(entry.key);
                          return FilterChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedEVStats.add(entry.key);
                                } else {
                                  selectedEVStats.remove(entry.key);
                                }
                              });
                              _applyFilter();
                            },
                            selectedColor: evStatColors[entry.key]?.withOpacity(0.3),
                            checkmarkColor: evStatColors[entry.key],
                            avatar: isSelected
                                ? null
                                : Icon(Icons.fitness_center, size: 16, color: evStatColors[entry.key]),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Game version filter
                Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Game (optional):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: gameVersions.entries.map((entry) {
                          final isSelected = selectedVersions.contains(entry.key);
                          return FilterChip(
                            label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedVersions.add(entry.key);
                                } else {
                                  selectedVersions.remove(entry.key);
                                }
                              });
                              _applyFilter();
                            },
                            selectedColor: Colors.blue.withOpacity(0.3),
                            checkmarkColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Active filters display
                if (selectedEVStats.isNotEmpty || selectedVersions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Filters:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        if (selectedEVStats.isNotEmpty)
                          Text(
                            'EV Stats: ${selectedEVStats.join(', ')}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        if (selectedVersions.isNotEmpty)
                          Text(
                            'Games: ${selectedVersions.map((v) => gameVersions[v]).join(', ')}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),

                const Divider(),

                // Pokemon count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Found ${filteredPokemonList.length} Pokemon',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isFiltering)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

                // Pokemon grid
                _buildPokemonGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPokemonGrid() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllPokemon,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredPokemonList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Pokemon found matching your filters',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredPokemonList.length,
      itemBuilder: (context, index) {
        final pokemon = filteredPokemonList[index];
        final evYields = pokemon['evYields'] as Map<String, int>;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Image.network(
                    pokemon['image'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.catching_pokemon, size: 50);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${pokemon['id'].toString().padLeft(4, '0')}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  pokemon['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Display EV yields
                if (evYields.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: evYields.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: evStatColors[entry.key]?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: evStatColors[entry.key]?.withOpacity(0.5) ?? Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '+${entry.value} ${_abbreviateStat(entry.key)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: evStatColors[entry.key],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    'No EVs',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _abbreviateStat(String stat) {
    switch (stat) {
      case 'HP':
        return 'HP';
      case 'Attack':
        return 'Atk';
      case 'Defense':
        return 'Def';
      case 'Sp. Atk':
        return 'SpA';
      case 'Sp. Def':
        return 'SpD';
      case 'Speed':
        return 'Spd';
      default:
        return stat;
    }
  }
}
