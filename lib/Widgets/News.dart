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

      var title = doc.querySelectorAll('td.fooleft');
      var description = doc.querySelectorAll('td.foocontent');

      List<Map<String, String>> raidsList = [];

      for (var i = 0; i < title.length && i < description.length; i++) {
        raidsList.add({'title': title[i].text, 'description': description[i].text});
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

                  if (title.isNotEmpty && title != description) {
                    return Card(
                        elevation: 5,
                        color: Theme.of(context).colorScheme.onBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
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
