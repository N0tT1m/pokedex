import 'package:advanced_search/advanced_search.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:requests/requests.dart';
import 'package:html/parser.dart';

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
      const String baseUrl = 'https://pokemondb.net/pokedex/national';
      var r = await Requests.get(baseUrl);
      r.raiseForStatus();
      String body = r.content();

      var doc = parse(body);
      var aTags = doc.querySelectorAll('a');

      List<String> names = [];
      for (var i = 0; i < aTags.length; i++) {
        if (aTags[i].className == "ent-name") {
          names.add(aTags[i].text);
        }
      }

      return names;
    } catch (e) {
      print('Error fetching Pokemon list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _makeRequest(String pokemon) async {
    try {
      const String baseUrl = 'https://pokemondb.net/pokedex/';
      var r = await Requests.get('$baseUrl$pokemon');
      r.raiseForStatus();
      String body = r.content();

      var doc = parse(body);
      var aTags = doc.querySelectorAll('a');
      var h2Tags = doc.querySelectorAll('h2');
      var tables = doc.querySelectorAll('table.vitals-table');
      var pokemonGames = doc.querySelectorAll('table.vitals-table');
      var evolution = doc.querySelectorAll('div.infocard-list-evo');

      // Reset state for new search
      text.clear();
      headers.clear();
      data.clear();
      tableDataFormatted.clear();
      mappedData.clear();
      pokemonLocations.clear();
      listOfEvolution.clear();
      evolutions.clear();

      var pokemonImg = aTags
          .where((element) =>
              element.attributes['href']?.contains('https://img.pokemondb.net/artwork/') ?? false)
          .toList();

      var it = h2Tags.iterator;
      while (it.moveNext()) {
        if (!text.contains(it.current.text)) {
          text.add(it.current.text);
        }
      }

      var tableIT = tables.iterator;
      while (tableIT.moveNext()) {
        doc = parse(tableIT.current.outerHtml);

        var tableHeaders = doc.querySelectorAll('th');
        var tableData = doc.querySelectorAll('td');

        List<String> localHeaders = [];
        List<String> localData = [];

        for (var header in tableHeaders) {
          if (header.text.contains('National')) {
            localHeaders.add(header.text.replaceAll('National №', 'National'));
          } else if (header.text.contains('Local')) {
            localHeaders.add(header.text.replaceAll('Local №', 'Local'));
          } else {
            localHeaders.add(header.text);
          }
        }

        for (var td in tableData) {
          localData.add(td.text.replaceAll('\n', ''));
        }

        for (var i = 0; i < localHeaders.length && i < localData.length; i++) {
          tableDataFormatted.addAll({localHeaders[i]: localData[i]});
        }
      }

      for (var i = 0; i < text.length; i++) {
        mappedData.addAll({text[i]: tableDataFormatted});
      }

      // Locations Logic - with bounds checking
      if (pokemonGames.length > 5) {
        var gameData = pokemonGames[5].outerHtml;
        var gameDataDoc = parse(gameData);
        var pokemonGameData = gameDataDoc.getElementsByTagName("th");
        var gameLocations = gameDataDoc.getElementsByTagName("td");

        for (var i = 0; i < gameLocations.length && i < pokemonGameData.length; i++) {
          pokemonLocations.add("${pokemonGameData[i].text}: ${gameLocations[i].text}");
        }
      }

      for (var i = 0; i < evolution.length; i++) {
        var html = evolution[i].outerHtml;
        var parsedHtml = parse(html);
        var listOfChildren = parsedHtml.children;

        for (var i = 0; i < listOfChildren.length; i++) {
          var img = listOfChildren[i].getElementsByTagName('img');
          var pokemonElements = listOfChildren[i].getElementsByTagName('a.ent-name');

          for (var j = 0; j < img.length && j < pokemonElements.length; j++) {
            var srcAttr = img[j].attributes['src'];
            if (srcAttr != null && srcAttr.contains('https://img.pokemondb.net/sprites/')) {
              listOfEvolution.add({
                "img": srcAttr,
                "info": pokemonElements[j].text,
              });
            }
          }
        }

        for (var i = 0; i < listOfChildren.length; i++) {
          var pokemonEvolutions = listOfChildren[i].getElementsByTagName('span.infocard-arrow');

          for (var evolution in pokemonEvolutions) {
            evolutions.add({"evolution": evolution.text});
          }
        }
      }

      formattedOutput = {
        'image': pokemonImg.isNotEmpty && pokemonImg[0].attributes['href'] != null
            ? pokemonImg[0].attributes['href']!
            : '',
        'titles': text,
        'data': mappedData,
        'evolution': listOfEvolution,
        'locations': pokemonLocations,
        'requiredToEvolve': evolutions,
      };

      return formattedOutput;
    } catch (e) {
      print('Error fetching Pokemon data: $e');
      return {
        'image': '',
        'titles': ['Error'],
        'data': {},
        'evolution': [],
        'locations': [],
        'requiredToEvolve': [],
      };
    }
  }

  Widget getPokemonWidget() {
    for (var i = 0; i < pokemonLocations.length; i++) {
      listOfWidgets.add(Text(pokemonLocations[i]));
      listOfWidgets.add(const Padding(padding: EdgeInsets.all(5)));
    }

    return Column(children: listOfWidgets);
  }

  Widget getEggs() {
    if (_pokemonData == null) return const SizedBox.shrink();

    final baseStats = _pokemonData!['data']?['Base stats'] as Map<String, dynamic>?;
    if (baseStats == null) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        Text(
          'Egg Groups: ${baseStats['Egg Groups'] ?? 'N/A'}',
        ),
        const Padding(
          padding: EdgeInsets.all(5),
        ),
        Text(
          'Gender: ${baseStats['Gender'] ?? 'N/A'}',
        ),
        const Padding(
          padding: EdgeInsets.all(5),
        ),
        Text(
          'Egg Cycles: ${baseStats['Egg cycles'] ?? 'N/A'}',
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
    final requiredToEvolve = _getSafeList('requiredToEvolve') as List;
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
              if (titles.length > 5)
                Text(
                  '${titles[5]}\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (evolutions.isEmpty || evolutions.length == 1)
                const Column(
                  children: <Widget>[
                    Text('This pokemon does not evolve.'),
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
                      if (evolutions[i]['info'] != null)
                        Text('${evolutions[i]['info']}'),
                      const Padding(padding: EdgeInsets.all(5)),
                      if (i < requiredToEvolve.length &&
                          requiredToEvolve[i]['evolution'] != null)
                        Text('${requiredToEvolve[i]['evolution']}'),
                      if (i < evolutions.length - 1)
                        const Padding(padding: EdgeInsets.all(5)),
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
        ? AdvancedSearch(
            searchItems: names,
            maxElementsToDisplay: 5,
            onItemTap: (index, text) {
              // Handle item selection
            },
            onSearchClear: () {
              // Handle search clear
            },
            onSubmitted: (value, value2) {
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
            },
            onEditingProgress: (value, value2) {
              // Handle editing progress
            },
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
                                    'National No: ${_getSafeData('data', 'Base stats', 'National')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Type: ${_getSafeData('data', 'Base stats', 'Type')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Species: ${_getSafeData('data', 'Base stats', 'Species')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Height: ${_getSafeData('data', 'Base stats', 'Height')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Weight: ${_getSafeData('data', 'Base stats', 'Weight')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Abilities: ${_getSafeData('data', 'Base stats', 'Abilities')}',
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
                                    'EV yield: ${_getSafeData('data', 'Base stats', 'EV yield')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Catch rate: ${_getSafeData('data', 'Base stats', 'Catch rate')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Base Friendship: ${_getSafeData('data', 'Base stats', 'Base Friendship')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Base Exp.: ${_getSafeData('data', 'Base stats', 'Base Exp.')}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5),
                                  ),
                                  Text(
                                    'Growth Rate: ${_getSafeData('data', 'Base stats', 'Growth Rate')}',
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
