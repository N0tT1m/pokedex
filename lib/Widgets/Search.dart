import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';
import '../services/pokemondb_service.dart';

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
          print('Game: $game, Locations: ${locations.length}');
          if (locations.isNotEmpty) {
            pokemonLocations.add('$game: ${locations.join(', ')}');
          }
        }

        print('Total location strings created: ${pokemonLocations.length}');

        // If no data from PokemonDB, add a message
        if (pokemonLocations.isEmpty) {
          pokemonLocations.add('No location data available');
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
        'evolution': [],
        'locations': [],
      };
    }
  }

  Widget getPokemonWidget() {
    // Build a fresh list of location widgets
    final List<Widget> locationWidgets = [];

    for (var i = 0; i < pokemonLocations.length; i++) {
      locationWidgets.add(
        Text(
          pokemonLocations[i],
          style: const TextStyle(fontSize: 14),
        ),
      );
      if (i < pokemonLocations.length - 1) {
        locationWidgets.add(const SizedBox(height: 8));
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

    return Column(
      children: <Widget>[
        Text(
          'Egg Groups: ${breedingData['Egg Groups'] ?? 'N/A'}',
        ),
        const Padding(
          padding: EdgeInsets.all(5),
        ),
        Text(
          'Gender: ${breedingData['Gender'] ?? 'N/A'}',
        ),
        const Padding(
          padding: EdgeInsets.all(5),
        ),
        Text(
          'Egg Cycles: ${breedingData['Egg Cycles'] ?? 'N/A'}',
        ),
        const Padding(
          padding: EdgeInsets.all(5),
        ),
      ],
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

  Widget _buildEvolutionCard() {
    final evolutions = _getSafeList('evolution') as List;
    final titles = _getSafeList('titles') as List;

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
              if (evolutions.isEmpty || evolutions.length == 1)
                const Column(
                  children: <Widget>[
                    Text('This Pokémon does not evolve.'),
                  ],
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < evolutions.length; i++) ...[
                      if (evolutions[i]['img'] != null)
                        Image.network(
                          evolutions[i]['img'],
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error);
                          },
                        ),
                      const Padding(padding: EdgeInsets.all(5)),
                      if (evolutions[i]['name'] != null)
                        Text(
                          '${evolutions[i]['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const Padding(padding: EdgeInsets.all(5)),
                      if (evolutions[i]['info'] != null &&
                          evolutions[i]['info'] != evolutions[i]['name'])
                        Text('${evolutions[i]['info']}'),
                      if (i < evolutions.length - 1)
                        const Column(
                          children: [
                            Padding(padding: EdgeInsets.all(5)),
                            Icon(Icons.arrow_downward),
                            Padding(padding: EdgeInsets.all(5)),
                          ],
                        ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                  _getPokemon().then((value) {
                    if (mounted) {
                      setState(() => names = value);
                    }
                  });
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _pokemonData == null
        ? Container(
            padding: const EdgeInsets.all(16.0),
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
                        fillColor: Colors.red.withOpacity(0.3),
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
                                        color: Colors.white.withOpacity(0.2),
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
        : SizedBox(
            height: MediaQuery.of(context).size.height - 130,
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
                    _buildEvolutionCard(),
                    if (pokemonLocations.isNotEmpty)
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
                                if ((_getSafeList('titles') as List).length > 10)
                                  Text(
                                    '${(_getSafeList('titles') as List)[10]}\n',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
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
