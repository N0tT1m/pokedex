import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';

class Generations extends StatefulWidget {
  const Generations({Key? key}) : super(key: key);

  @override
  State<Generations> createState() => _GenerationsState();
}

class _GenerationsState extends State<Generations> {
  List<Map<String, dynamic>> pokemonList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _getPokemon().then((value) {
      if (mounted) {
        setState(() {
          pokemonList = value;
          isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading Pokemon: $error';
          isLoading = false;
        });
      }
      print('Error loading Pokemon: $error');
    });
  }

  Future<List<Map<String, dynamic>>> _getPokemon() async {
    try {
      // Fetch all Pokemon from PokeAPI (limit 1025 for Gen 1-9)
      final pokemonListData = await PokeApiService.getPokemonList(limit: 1025);

      final List<Map<String, dynamic>> formattedPokemon = [];

      // Format basic list without fetching individual Pokemon details
      // This is faster for initial display
      for (int i = 0; i < pokemonListData.length; i++) {
        final pokemonId = PokeApiService.extractIdFromUrl(pokemonListData[i]['url']) ?? (i + 1);
        formattedPokemon.add({
          'id': pokemonId,
          'name': PokemonDataFormatter.capitalize(pokemonListData[i]['name']),
          'types': [],
          'image': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png',
        });
      }

      return formattedPokemon;
    } catch (e) {
      print('Error fetching Pokemon data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                  isLoading = true;
                });
                _getPokemon().then((value) {
                  if (mounted) {
                    setState(() {
                      pokemonList = value;
                      isLoading = false;
                    });
                  }
                }).catchError((error) {
                  if (mounted) {
                    setState(() {
                      errorMessage = 'Error loading Pokemon: $error';
                      isLoading = false;
                    });
                  }
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (pokemonList.isEmpty) {
      return const Center(
        child: Text('No Pokemon data available.'),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height - 60,
      child: ListView.builder(
        itemCount: pokemonList.length,
        itemBuilder: (context, index) {
          final pokemon = pokemonList[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  if (pokemon['image'] != null && pokemon['image'].isNotEmpty)
                    Image.network(
                      pokemon['image'],
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 50);
                      },
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '#${pokemon['id'].toString().padLeft(4, '0')} ${pokemon['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
