import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class MoveTutorScreen extends StatefulWidget {
  const MoveTutorScreen({Key? key}) : super(key: key);

  @override
  State<MoveTutorScreen> createState() => _MoveTutorScreenState();
}

class _MoveTutorScreenState extends State<MoveTutorScreen> {
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
      final r = await Requests.get('${PokeApiService.baseUrl}/move-tutor');
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
      setState(() { _error = 'Could not load tutors'; _isLoading = false; });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _all.where((t) {
        final gameMatch = _selectedGame == 'All' || t['game'] == _selectedGame;
        final queryMatch = _query.isEmpty ||
            (t['move_name'] as String).toLowerCase().contains(_query) ||
            ((t['location'] as String?) ?? '').toLowerCase().contains(_query);
        return gameMatch && queryMatch;
      }).toList();
    });
  }

  String _fmt(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Move Tutors'), backgroundColor: Colors.red),
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
                                hintText: 'Search move or location...',
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
                        child: Text('${_filtered.length} tutor moves', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final t = _filtered[i];
                          final move = _fmt(t['move_name'] as String);
                          final game = t['game'] as String;
                          final location = t['location'] as String?;
                          final cost = t['cost'] as String?;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              dense: true,
                              title: Text(move, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: location != null ? Text(location, style: const TextStyle(fontSize: 12)) : null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(game, style: TextStyle(fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                                  if (cost != null) Text(cost, style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
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
