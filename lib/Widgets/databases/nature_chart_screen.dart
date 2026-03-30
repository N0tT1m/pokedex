import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/iv_calculator_service.dart';
import '../../services/pokeapi_service.dart';

class NatureChartScreen extends StatefulWidget {
  const NatureChartScreen({Key? key}) : super(key: key);

  @override
  State<NatureChartScreen> createState() => _NatureChartScreenState();
}

class _NatureChartScreenState extends State<NatureChartScreen> {
  // Enriched nature data from API, keyed by lowercase nature name
  Map<String, Map<String, String>> _apiNatureData = {};

  @override
  void initState() {
    super.initState();
    _fetchNaturesFromApi();
  }

  Future<void> _fetchNaturesFromApi() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/nature');
      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results']);
        final Map<String, Map<String, String>> apiData = {};
        for (final nature in results) {
          final name = (nature['name'] as String).toLowerCase();
          apiData[name] = {
            'increased_stat': nature['increased_stat']?.toString() ?? '',
            'decreased_stat': nature['decreased_stat']?.toString() ?? '',
          };
        }
        if (mounted) {
          setState(() {
            _apiNatureData = apiData;
          });
        }
      }
    } catch (_) {
      // API enrichment failed; fall back to hardcoded data silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nature Chart'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Natures affect stats by +10% / -10%',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataTable(
              columnSpacing: 16,
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 36,
              columns: const [
                DataColumn(label: Text('Nature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('+10%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green))),
                DataColumn(label: Text('-10%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red))),
              ],
              rows: IVCalculatorService.allNatures.map((nature) {
                String increased = '-';
                String decreased = '-';

                // Try API data first, fall back to hardcoded modifiers
                final apiEntry = _apiNatureData[nature.toLowerCase()];
                if (apiEntry != null && apiEntry['increased_stat']!.isNotEmpty) {
                  increased = apiEntry['increased_stat']!;
                  decreased = apiEntry['decreased_stat']!;
                } else {
                  final mods = IVCalculatorService.getNatureModifiers(nature);
                  for (var entry in mods.entries) {
                    if (entry.value > 1.0) increased = entry.key;
                    if (entry.value < 1.0) decreased = entry.key;
                  }
                }

                final isNeutral = increased == '-';

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    return isNeutral ? Colors.grey.withValues(alpha: 0.1) : null;
                  }),
                  cells: [
                    DataCell(Text(nature, style: TextStyle(
                      fontWeight: isNeutral ? FontWeight.normal : FontWeight.bold,
                      fontSize: 13,
                    ))),
                    DataCell(Text(increased, style: TextStyle(
                      color: increased != '-' ? Colors.green : Colors.grey,
                      fontSize: 13,
                    ))),
                    DataCell(Text(decreased, style: TextStyle(
                      color: decreased != '-' ? Colors.red : Colors.grey,
                      fontSize: 13,
                    ))),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Quick Reference', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Physical Attackers: Adamant (+Atk/-SpA) or Jolly (+Spe/-SpA)', style: TextStyle(fontSize: 12)),
                    Text('Special Attackers: Modest (+SpA/-Atk) or Timid (+Spe/-Atk)', style: TextStyle(fontSize: 12)),
                    Text('Physical Walls: Impish (+Def/-SpA) or Bold (+Def/-Atk)', style: TextStyle(fontSize: 12)),
                    Text('Special Walls: Careful (+SpD/-SpA) or Calm (+SpD/-Atk)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
