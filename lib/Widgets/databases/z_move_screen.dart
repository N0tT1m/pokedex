import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

class ZMoveScreen extends StatefulWidget {
  const ZMoveScreen({Key? key}) : super(key: key);

  @override
  State<ZMoveScreen> createState() => _ZMoveScreenState();
}

class _ZMoveScreenState extends State<ZMoveScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';
  String _typeFilter = 'All';
  List<String> _types = ['All'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Requests.get('${PokeApiService.baseUrl}/z-move');
      if (r.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(r.json()['results'] ?? []);
        final typeSet = <String>{'All'};
        for (final z in results) {
          if (z['type'] != null) typeSet.add(_fmt(z['type'] as String));
        }
        setState(() {
          _all = results;
          _filtered = results;
          _types = typeSet.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Server error ${r.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not load Z-Moves'; _isLoading = false; });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _all.where((z) {
        final nameMatch = _query.isEmpty || (z['name'] as String).toLowerCase().contains(_query);
        final typeMatch = _typeFilter == 'All' || _fmt(z['type'] as String? ?? '') == _typeFilter;
        return nameMatch && typeMatch;
      }).toList();
    });
  }

  String _fmt(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Z-Moves'), backgroundColor: Colors.red),
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
                          hintText: 'Search Z-Moves...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          filled: true, fillColor: Colors.white,
                        ),
                        onChanged: (v) { _query = v.toLowerCase(); _filter(); },
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: _types.map((t) {
                          final sel = _typeFilter == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(t, style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
                              selected: sel,
                              selectedColor: AppTheme.typeColors[t] ?? Colors.red,
                              onSelected: (_) { _typeFilter = t; _filter(); },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('${_filtered.length} Z-Moves', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final z = _filtered[i];
                          final typeName = _fmt(z['type'] as String? ?? '');
                          final typeColor = AppTheme.typeColors[typeName] ?? Colors.grey;
                          final power = z['power'];
                          final baseMove = z['base_move'] as String?;
                          final category = z['category'] as String? ?? '';
                          final effect = z['effect'] as String? ?? '';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(_fmt(z['name'] as String), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                      if (typeName.isNotEmpty) Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(8)),
                                        child: Text(typeName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (power != null) _statChip('Power: $power', Colors.orange),
                                      if (category.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        _statChip(category[0].toUpperCase() + category.substring(1),
                                          category == 'physical' ? Colors.orange : category == 'special' ? Colors.blue : Colors.grey),
                                      ],
                                      if (baseMove != null) ...[
                                        const SizedBox(width: 6),
                                        _statChip('Base: ${_fmt(baseMove)}', Colors.teal),
                                      ],
                                    ],
                                  ),
                                  if (effect.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(effect, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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

  Widget _statChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
  );
}
