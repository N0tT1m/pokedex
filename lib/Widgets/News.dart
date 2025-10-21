import 'package:flutter/material.dart';

import 'package:requests/requests.dart';
import 'package:html/parser.dart' show parse;

class News extends StatefulWidget {
  const News({Key? key}) : super(key: key);

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  late Future<List<Map<String, String>>> raids;

  @override
  void initState() {
    super.initState();
    raids = loadCards();
  }

  Future<List<Map<String, String>>> loadCards() async {
    try {
      // Fetch Tera Raid Battle Events from Serebii
      // This covers Pokemon Scarlet & Violet (the only games with Tera Raids)
      var r = await Requests.get(
          'https://www.serebii.net/scarletviolet/teraraidbattleevents.shtml');
      r.raiseForStatus();
      String body = r.content();

      var doc = parse(body);

      // Serebii uses a table format with alternating title/description cells
      var title = doc.querySelectorAll('td.fooleft');
      var description = doc.querySelectorAll('td.foocontent');

      List<Map<String, String>> raidsList = [];

      // Parse each raid event
      for (var i = 0; i < title.length && i < description.length; i++) {
        final titleText = title[i].text.trim();
        final descText = description[i].text.trim();

        // Only add if we have valid data
        if (titleText.isNotEmpty && descText.isNotEmpty) {
          // Try to extract additional metadata
          String dateInfo = '';
          String pokemonName = '';
          String raidLevel = '';
          String teraType = '';

          // Extract date from description if present
          final dateMatch = RegExp(r'(\d{1,2}(?:st|nd|rd|th)?\s+\w+\s+\d{4})')
              .firstMatch(descText);
          if (dateMatch != null) {
            dateInfo = dateMatch.group(0) ?? '';
          }

          // Extract raid level (e.g., "5★", "6★", "7★")
          final levelMatch = RegExp(r'([1-7])★').firstMatch(descText);
          if (levelMatch != null) {
            raidLevel = '${levelMatch.group(1)}★';
          }

          // Extract Tera Type if mentioned
          final teraTypeMatch = RegExp(
            r'(Normal|Fire|Water|Electric|Grass|Ice|Fighting|Poison|Ground|Flying|Psychic|Bug|Rock|Ghost|Dragon|Dark|Steel|Fairy)\s+Tera\s+Type',
            caseSensitive: false,
          ).firstMatch(descText);
          if (teraTypeMatch != null) {
            teraType = teraTypeMatch.group(1) ?? '';
          }

          // Extract Pokemon name from title
          pokemonName = titleText;

          raidsList.add({
            'title': titleText,
            'description': descText,
            'date': dateInfo,
            'pokemon': pokemonName,
            'level': raidLevel,
            'teraType': teraType,
          });
        }
      }

      return raidsList;
    } catch (e) {
      print('Error loading raid data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
        future: raids,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.error, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading raid data',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        raids = loadCards();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No raid data available',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            );
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height - 60,
            child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final raid = snapshot.data![index];
                  final title = raid['title'] ?? '';
                  final description = raid['description'] ?? '';
                  final date = raid['date'] ?? '';
                  final level = raid['level'] ?? '';
                  final teraType = raid['teraType'] ?? '';

                  if (title.isNotEmpty && title != description) {
                    return Card(
                        elevation: 5,
                        color: Theme.of(context).colorScheme.onBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  if (level.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        level,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (teraType.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tera Type: $teraType',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              if (date.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ));
                  }

                  return const SizedBox.shrink();
                }),
          );
        });
  }
}
