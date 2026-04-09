import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class BattleFacilitiesScreen extends StatefulWidget {
  const BattleFacilitiesScreen({Key? key}) : super(key: key);

  @override
  State<BattleFacilitiesScreen> createState() => _BattleFacilitiesScreenState();
}

class _BattleFacilitiesScreenState extends State<BattleFacilitiesScreen> {
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
      final r = await Requests.get('${PokeApiService.baseUrl}/battle-facility');
      if (r.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(r.json()['results'] ?? []);
        final gameSet = <String>{'All'};
        for (final f in results) { gameSet.add(f['game'] as String); }
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
      setState(() { _error = 'Could not load facilities'; _isLoading = false; });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _all.where((f) {
        final gameMatch = _selectedGame == 'All' || f['game'] == _selectedGame;
        final queryMatch = _query.isEmpty || (f['name'] as String).toLowerCase().contains(_query);
        return gameMatch && queryMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battle Facilities'), backgroundColor: Colors.red),
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
                                hintText: 'Search facilities...',
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
                        child: Text('${_filtered.length} facilities', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final f = _filtered[i];
                          final name = f['name'] as String;
                          final game = f['game'] as String;
                          final region = f['region'] as String?;
                          final type = f['facility_type'] as String?;
                          final desc = f['description'] as String?;
                          final currency = f['currency'] as String?;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
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
                                      if (region != null) Text(region, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      if (type != null) Text(type, style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                                      if (currency != null) Text('Currency: $currency', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                                    ],
                                  ),
                                  if (desc != null) ...[
                                    const SizedBox(height: 6),
                                    Text(desc, style: const TextStyle(fontSize: 12)),
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
