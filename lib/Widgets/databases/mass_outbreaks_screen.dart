import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../pokemon/pokemon_detail_sheet.dart';

class MassOutbreaksScreen extends StatefulWidget {
  const MassOutbreaksScreen({Key? key}) : super(key: key);

  @override
  State<MassOutbreaksScreen> createState() => _MassOutbreaksScreenState();
}

class _MassOutbreaksScreenState extends State<MassOutbreaksScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  List<String> _games = ['All'];
  String _selectedGame = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Requests.get('${PokeApiService.baseUrl}/mass-outbreaks');
      if (r.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(r.json()['results'] ?? []);
        final gameSet = <String>{'All'};
        for (final o in results) { gameSet.add(o['game'] as String); }
        setState(() {
          _all = results;
          _filtered = results;
          _games = gameSet.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Server error ${r.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not load outbreaks'; _isLoading = false; });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _all.where((o) {
        final gameMatch = _selectedGame == 'All' || o['game'] == _selectedGame;
        final queryMatch = _query.isEmpty ||
            (o['pokemon_name'] as String).toLowerCase().contains(_query) ||
            ((o['location'] as String?) ?? '').toLowerCase().contains(_query);
        return gameMatch && queryMatch;
      }).toList();
    });
  }

  String _fmt(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mass Outbreaks'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search Pokemon or location...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                filled: true, fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onChanged: (v) { _query = v.toLowerCase(); _filter(); },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedGame,
                            items: _games.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) { if (v != null) { _selectedGame = v; _filter(); } },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${_filtered.length} outbreaks', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final o = _filtered[i];
                          final pokemon = _fmt(o['pokemon_name'] as String);
                          final game = o['game'] as String;
                          final region = o['region'] as String?;
                          final location = o['location'] as String?;
                          final notes = o['notes'] as String?;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              title: Text(pokemon, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Text(game, style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                                      if (region != null) Text(region, style: const TextStyle(fontSize: 12)),
                                      if (location != null) Text('📍 $location', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  if (notes != null)
                                    Text(notes, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => showPokemonDetailSheet(context, o['pokemon_name'] as String),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
