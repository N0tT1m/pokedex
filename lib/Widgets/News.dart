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
      var r = await Requests.get(
          'https://www.serebii.net/scarletviolet/teraraidbattleevents.shtml');
      r.raiseForStatus();
      String body = r.content();

      var doc = parse(body);

      // Try multiple selector strategies since Serebii's layout may change
      var title = doc.querySelectorAll('td.fooleft');
      var description = doc.querySelectorAll('td.foocontent');

      // Fallback: try other common Serebii table structures
      if (title.isEmpty || description.isEmpty) {
        final tables = doc.querySelectorAll('table.dextable');
        for (var table in tables) {
          final rows = table.querySelectorAll('tr');
          List<Map<String, String>> raidsList = [];
          for (var row in rows) {
            final cells = row.querySelectorAll('td');
            if (cells.length >= 2) {
              final titleText = cells[0].text.trim();
              final descText = cells[1].text.trim();
              if (titleText.isNotEmpty && descText.isNotEmpty) {
                raidsList.add(_parseRaidEntry(titleText, descText));
              }
            }
          }
          if (raidsList.isNotEmpty) return raidsList;
        }
      }

      List<Map<String, String>> raidsList = [];

      for (var i = 0; i < title.length && i < description.length; i++) {
        final titleText = title[i].text.trim();
        final descText = description[i].text.trim();

        if (titleText.isNotEmpty && descText.isNotEmpty) {
          raidsList.add(_parseRaidEntry(titleText, descText));
        }
      }

      return raidsList;
    } catch (e) {
      print('Error loading raid data: $e');
      return [];
    }
  }

  Map<String, String> _parseRaidEntry(String titleText, String descText) {
    String dateInfo = '';
    String raidLevel = '';
    String teraType = '';

    final dateMatch = RegExp(r'(\d{1,2}(?:st|nd|rd|th)?\s+\w+\s+\d{4})')
        .firstMatch(descText);
    if (dateMatch != null) {
      dateInfo = dateMatch.group(0) ?? '';
    }

    final levelMatch = RegExp(r'([1-7])★').firstMatch(descText);
    if (levelMatch != null) {
      raidLevel = '${levelMatch.group(1)}★';
    }

    final teraTypeMatch = RegExp(
      r'(Normal|Fire|Water|Electric|Grass|Ice|Fighting|Poison|Ground|Flying|Psychic|Bug|Rock|Ghost|Dragon|Dark|Steel|Fairy)\s+Tera\s+Type',
      caseSensitive: false,
    ).firstMatch(descText);
    if (teraTypeMatch != null) {
      teraType = teraTypeMatch.group(1) ?? '';
    }

    return {
      'title': titleText,
      'description': descText,
      'date': dateInfo,
      'pokemon': titleText,
      'level': raidLevel,
      'teraType': teraType,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Events'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Map<String, String>>>(
          future: raids,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
                padding: const EdgeInsets.all(8),
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
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                    color: Colors.grey.shade600,
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
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ));
                  }

                  return const SizedBox.shrink();
                });
          }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Could not load event data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  raids = loadCards();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Active Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no Tera Raid Battle events currently listed. Check back later for new events!',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  raids = loadCards();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
