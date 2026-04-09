import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class EventPokemonScreen extends StatefulWidget {
  const EventPokemonScreen({Key? key}) : super(key: key);

  @override
  State<EventPokemonScreen> createState() => _EventPokemonScreenState();
}

class _EventPokemonScreenState extends State<EventPokemonScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Requests.get('${PokeApiService.baseUrl}/event-pokemon');
      if (r.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(r.json()['results'] ?? []);
        setState(() { _all = results; _filtered = results; _isLoading = false; });
      } else {
        setState(() { _error = 'Server error ${r.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not load events'; _isLoading = false; });
    }
  }

  void _filter(String q) {
    _query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((e) =>
        (e['name'] as String).toLowerCase().contains(_query) ||
        ((e['game'] as String?) ?? '').toLowerCase().contains(_query) ||
        ((e['ot_name'] as String?) ?? '').toLowerCase().contains(_query)
      ).toList();
    });
  }

  String _fmt(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Pokemon'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, game, OT...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          filled: true, fillColor: Colors.white,
                        ),
                        onChanged: _filter,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${_filtered.length} events', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final e = _filtered[i];
                          final name = _fmt(e['name'] as String);
                          final game = e['game'] as String?;
                          final year = e['year'] as int?;
                          final level = e['level'] as int?;
                          final otName = e['ot_name'] as String?;
                          final heldItem = e['held_item'] as String?;
                          final method = e['distribution_method'] as String?;
                          final notes = e['notes'] as String?;
                          final moves = List<String>.from(e['moves'] ?? []);
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
                                      if (year != null) Text('$year', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (game != null) _chip(game, Colors.red),
                                      if (level != null) _chip('Lv. $level', Colors.blue),
                                      if (otName != null) _chip('OT: $otName', Colors.teal),
                                      if (heldItem != null) _chip('Holds: ${_fmt(heldItem)}', Colors.green),
                                      if (method != null) _chip(method, Colors.orange),
                                    ],
                                  ),
                                  if (moves.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      children: moves.map((m) => Chip(
                                        label: Text(_fmt(m), style: const TextStyle(fontSize: 11)),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                      )).toList(),
                                    ),
                                  ],
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

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4))),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
  );
}
