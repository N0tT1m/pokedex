import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import 'package:html/parser.dart' show parse;

class Generations extends StatefulWidget {
  const Generations({Key? key}) : super(key: key);

  @override
  State<Generations> createState() => _GenerationsState();
}

class _GenerationsState extends State<Generations> {
  List<String> pokemonNames = [];
  List<String> names = [];
  List<String> pokemonImages = [];
  List<String> numOfPokemon = [];
  List<String> typesOfPokemon = [];

  @override
  void initState() {
    super.initState();
    _getPokemon().then((value) {
      if (mounted) {
        setState(() {
          pokemonNames = value["pokemonNames"] ?? [];
          pokemonImages = value["pokemonImages"] ?? [];
          numOfPokemon = value["numOfPokemon"] ?? [];
          typesOfPokemon = value["typesOfPokemon"] ?? [];
        });
      }
    }).catchError((error) {
      print('Error loading Pokemon: $error');
    });
  }

  Future<Map<String, dynamic>> _getPokemon() async {
    try {
      const String baseUrl = 'https://pokemondb.net/pokedex/national';
      var r = await Requests.get(baseUrl);
      r.raiseForStatus();
      String body = r.content();

      var doc = parse(body);
      var aTags = doc.querySelectorAll('a');
      var imgs = doc.querySelectorAll('img');
      var infoAboutPokemon = doc.querySelectorAll('small');

      List<String> localNumOfPokemon = [];
      List<String> localTypesOfPokemon = [];
      List<String> localPokemonImages = [];
      List<String> localPokemonNames = [];

      for (var i = 0; i < infoAboutPokemon.length; i++) {
        localNumOfPokemon.add(infoAboutPokemon[i].text);
        if (i + 1 < infoAboutPokemon.length) {
          localTypesOfPokemon.add(infoAboutPokemon[i + 1].text);
          i++;
        }
      }

      for (var i = 0; i < imgs.length; i++) {
        var srcAttr = imgs[i].attributes['src'];
        if (srcAttr != null && srcAttr.contains("https://img.pokemondb.net/sprites/home/normal/")) {
          localPokemonImages.add(srcAttr);
        }
      }

      for (var i = 0; i < aTags.length; i++) {
        if (aTags[i].className == "ent-name") {
          localPokemonNames.add(aTags[i].text);
        }
      }

      Map<String, dynamic> pokemonData = {
        "numOfPokemon": localNumOfPokemon,
        "typesOfPokemon": localTypesOfPokemon,
        "pokemonImages": localPokemonImages,
        "pokemonNames": localPokemonNames
      };

      return pokemonData;
    } catch (e) {
      print('Error fetching Pokemon data: $e');
      return {
        "numOfPokemon": <String>[],
        "typesOfPokemon": <String>[],
        "pokemonImages": <String>[],
        "pokemonNames": <String>[]
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pokemonNames.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height - 60,
      child: ListView.builder(
        itemCount: pokemonNames.length,
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              children: <Widget>[
                if (index < pokemonImages.length)
                  Image.network(
                    pokemonImages[index],
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 50);
                    },
                  ),
                Text(pokemonNames[index]),
                if (index < typesOfPokemon.length)
                  Text(typesOfPokemon[index]),
              ],
            ),
          );
        },
      ),
    );
  }
}
