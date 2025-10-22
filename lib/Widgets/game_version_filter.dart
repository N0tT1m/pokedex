import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';

/// Widget for filtering and viewing Pokemon by game version(s)
class GameVersionFilter extends StatefulWidget {
  const GameVersionFilter({Key? key}) : super(key: key);

  @override
  State<GameVersionFilter> createState() => _GameVersionFilterState();
}

class _GameVersionFilterState extends State<GameVersionFilter> {
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

  Set<String> selectedVersions = {};

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

      for (int i = 0; i < pokemonListData.length; i++) {
        final pokemonId = PokeApiService.extractIdFromUrl(pokemonListData[i]['url']) ?? (i + 1);
        formattedPokemon.add({
          'id': pokemonId,
          'name': PokemonDataFormatter.capitalize(pokemonListData[i]['name']),
          'types': [],
          'image': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png',
        });
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

  Future<void> _applyFilter() async {
    if (selectedVersions.isEmpty) {
      setState(() {
        filteredPokemonList = pokemonList;
      });
      return;
    }

    setState(() {
      isFiltering = true;
    });

    try {
      // Get Pokemon IDs available in selected versions
      Set<int> availablePokemonIds = {};

      for (String version in selectedVersions) {
        final versionData = await PokeApiService.getVersionGroup(version);
        final List<dynamic> pokemonEntries = versionData['pokedexes'] ?? [];

        // Fetch each pokedex to get the Pokemon list
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

      // Filter the pokemon list
      final filtered = pokemonList.where((pokemon) {
        return availablePokemonIds.contains(pokemon['id']);
      }).toList();

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
              const Icon(Icons.videogame_asset, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pokemon by Game',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (selectedVersions.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  onPressed: _clearFilters,
                  tooltip: 'Clear all filters',
                ),
            ],
          ),
        ),

        // Game version chips
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Game Version(s):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gameVersions.entries.map((entry) {
                  final isSelected = selectedVersions.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
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
                    selectedColor: Colors.red.withOpacity(0.3),
                    checkmarkColor: Colors.red,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (selectedVersions.isNotEmpty)
                Text(
                  'Showing Pokemon from: ${selectedVersions.map((v) => gameVersions[v]).join(', ')}',
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

        // Pokemon list
        Expanded(
          child: _buildPokemonList(),
        ),
      ],
    );
  }

  Widget _buildPokemonList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
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
      );
    }

    if (filteredPokemonList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Pokemon found for the selected game version(s)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredPokemonList.length,
      itemBuilder: (context, index) {
        final pokemon = filteredPokemonList[index];
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.network(
                  pokemon['image'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.catching_pokemon, size: 50);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
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
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
