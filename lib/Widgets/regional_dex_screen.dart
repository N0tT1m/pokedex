import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';
import 'pokemon/pokemon_detail_sheet.dart';

class RegionalDexScreen extends StatefulWidget {
  const RegionalDexScreen({Key? key}) : super(key: key);

  @override
  State<RegionalDexScreen> createState() => _RegionalDexScreenState();
}

class _RegionalDexScreenState extends State<RegionalDexScreen> {
  static const List<Map<String, dynamic>> _dexes = [
    {'name': 'national', 'label': 'National Dex', 'icon': Icons.public, 'color': Colors.red},
    {'name': 'kanto', 'label': 'Kanto', 'icon': Icons.location_city, 'color': Colors.red},
    {'name': 'original-johto', 'label': 'Johto', 'icon': Icons.temple_buddhist, 'color': Colors.amber},
    {'name': 'hoenn', 'label': 'Hoenn', 'icon': Icons.water, 'color': Colors.blue},
    {'name': 'original-sinnoh', 'label': 'Sinnoh', 'icon': Icons.terrain, 'color': Colors.indigo},
    {'name': 'extended-sinnoh', 'label': 'Sinnoh (Platinum)', 'icon': Icons.terrain, 'color': Colors.grey},
    {'name': 'original-unova', 'label': 'Unova', 'icon': Icons.apartment, 'color': Colors.blueGrey},
    {'name': 'updated-unova', 'label': 'Unova (B2W2)', 'icon': Icons.apartment, 'color': Colors.brown},
    {'name': 'kalos-central', 'label': 'Kalos (Central)', 'icon': Icons.castle, 'color': Colors.deepPurple},
    {'name': 'kalos-coastal', 'label': 'Kalos (Coastal)', 'icon': Icons.castle, 'color': Colors.teal},
    {'name': 'kalos-mountain', 'label': 'Kalos (Mountain)', 'icon': Icons.castle, 'color': Colors.brown},
    {'name': 'original-alola', 'label': 'Alola', 'icon': Icons.sunny, 'color': Colors.orange},
    {'name': 'updated-alola', 'label': 'Alola (USUM)', 'icon': Icons.sunny, 'color': Colors.deepOrange},
    {'name': 'galar', 'label': 'Galar', 'icon': Icons.shield, 'color': Colors.purple},
    {'name': 'isle-of-armor', 'label': 'Isle of Armor', 'icon': Icons.fitness_center, 'color': Colors.lime},
    {'name': 'crown-tundra', 'label': 'Crown Tundra', 'icon': Icons.ac_unit, 'color': Colors.cyan},
    {'name': 'hisui', 'label': 'Hisui', 'icon': Icons.landscape, 'color': Colors.green},
    {'name': 'paldea', 'label': 'Paldea', 'icon': Icons.school, 'color': Colors.pink},
    {'name': 'kitakami', 'label': 'Kitakami', 'icon': Icons.park, 'color': Colors.lightGreen},
    {'name': 'blueberry', 'label': 'Blueberry', 'icon': Icons.science, 'color': Colors.blueAccent},
  ];

  String? _selectedDexName;
  String? _selectedDexLabel;
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loadDex(String name, String label) async {
    setState(() {
      _selectedDexName = name;
      _selectedDexLabel = label;
      _isLoading = true;
      _errorMessage = null;
      _entries = [];
    });

    try {
      final data = await PokeApiService.getPokedexByName(name);
      final rawEntries = data['pokemon_entries'] as List? ?? [];

      final entries = rawEntries.map<Map<String, dynamic>>((e) {
        final speciesName = e['pokemon_species']?['name'] ?? '';
        final speciesUrl = e['pokemon_species']?['url'] ?? '';
        final entryNumber = e['entry_number'] ?? 0;
        final nationalId = PokeApiService.extractIdFromUrl(speciesUrl) ?? entryNumber;
        return {
          'name': speciesName,
          'displayName': PokemonDataFormatter.capitalize(speciesName),
          'entryNumber': entryNumber,
          'nationalId': nationalId,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load $label Pokédex';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDexName == null) {
      return _buildDexSelector();
    }
    return _buildDexList();
  }

  Widget _buildDexSelector() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _dexes.length,
      itemBuilder: (context, index) {
        final dex = _dexes[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: dex['color'] as Color,
              child: Icon(dex['icon'] as IconData, color: Colors.white, size: 20),
            ),
            title: Text(
              dex['label'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadDex(dex['name'] as String, dex['label'] as String),
          ),
        );
      },
    );
  }

  Widget _buildDexList() {
    return Column(
      children: [
        Container(
          color: Colors.red.shade700,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() {
                  _selectedDexName = null;
                  _selectedDexLabel = null;
                  _entries = [];
                }),
              ),
              Expanded(
                child: Text(
                  '$_selectedDexLabel (${_entries.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadDex(_selectedDexName!, _selectedDexLabel!),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final entryNumber = entry['entryNumber'] as int;
                final nationalId = entry['nationalId'] as int;
                final name = entry['displayName'] as String;
                final apiName = entry['name'] as String;
                final spriteUrl =
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$nationalId.png';

                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.network(
                      spriteUrl,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.catching_pokemon, size: 32),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('#$entryNumber'),
                  onTap: () => showPokemonDetailSheet(context, apiName),
                );
              },
            ),
          ),
      ],
    );
  }
}
