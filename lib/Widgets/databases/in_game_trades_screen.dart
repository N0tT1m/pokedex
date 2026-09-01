import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class InGameTradesScreen extends StatefulWidget {
  const InGameTradesScreen({Key? key}) : super(key: key);

  @override
  State<InGameTradesScreen> createState() => _InGameTradesScreenState();
}

class _InGameTradesScreenState extends State<InGameTradesScreen> {
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
      final r = await Requests.get('${PokeApiService.baseUrl}/in-game-trades');
      if (r.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(r.json()['results'] ?? []);
        final gameSet = <String>{'All'};
        for (final t in results) { gameSet.add(t['game'] as String); }
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
      setState(() { _error = 'Could not load trades'; _isLoading = false; });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _all.where((t) {
        final gameMatch = _selectedGame == 'All' || t['game'] == _selectedGame;
        final queryMatch = _query.isEmpty ||
            (t['offered_pokemon'] as String).toLowerCase().contains(_query) ||
            (t['requested_pokemon'] as String).toLowerCase().contains(_query);
        return gameMatch && queryMatch;
      }).toList();
    });
  }

  String _fmt(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('In-Game Trades'), backgroundColor: Colors.red),
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
                                hintText: 'Search Pokemon...',
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
                        child: Text('${_filtered.length} trades', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final t = _filtered[i];
                          final offered = _fmt(t['offered_pokemon'] as String);
                          final requested = _fmt(t['requested_pokemon'] as String);
                          final game = t['game'] as String;
                          final location = t['location'] as String?;
                          final npc = t['npc_name'] as String?;
                          final item = t['offered_item'] as String?;
                          final level = t['offered_level'] as int?;
                          final notes = t['notes'] as String?;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(requested, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8),
                                              child: Icon(Icons.swap_horiz, color: Colors.grey),
                                            ),
                                            Text(offered, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade700)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                                        child: Text(game, style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (location != null) Text('📍 $location', style: const TextStyle(fontSize: 12)),
                                      if (npc != null) Text('NPC: $npc', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      if (level != null) Text('Lv. $level', style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                                      if (item != null) Text('Holds: ${_fmt(item)}', style: TextStyle(fontSize: 12, color: Colors.teal.shade600)),
                                    ],
                                  ),
                                  if (notes != null) ...[
                                    const SizedBox(height: 4),
                                    Text(notes, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
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
