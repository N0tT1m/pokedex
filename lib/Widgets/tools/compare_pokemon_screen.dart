import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

class ComparePokemonScreen extends StatefulWidget {
  const ComparePokemonScreen({Key? key}) : super(key: key);

  @override
  State<ComparePokemonScreen> createState() => _ComparePokemonScreenState();
}

class _ComparePokemonScreenState extends State<ComparePokemonScreen> {
  List<String> _pokemonNames = [];
  Map<String, dynamic>? _pokemon1;
  Map<String, dynamic>? _pokemon2;
  bool _isLoading = true;

  static const _statMap = {
    'hp': 'HP', 'attack': 'Attack', 'defense': 'Defense',
    'special-attack': 'Sp. Atk', 'special-defense': 'Sp. Def', 'speed': 'Speed'
  };

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    try {
      final list = await PokeApiService.getPokemonList(limit: 1025);
      setState(() {
        _pokemonNames = list.map((p) => p['name'] as String).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPokemon(String name, int slot) async {
    try {
      final data = await PokeApiService.getPokemon(name.toLowerCase());
      setState(() {
        if (slot == 1) _pokemon1 = data;
        else _pokemon2 = data;
      });
    } catch (_) {}
  }

  Map<String, int> _getStats(Map<String, dynamic> data) {
    final stats = <String, int>{};
    for (var s in data['stats']) {
      final mapped = _statMap[s['stat']['name']];
      if (mapped != null) stats[mapped] = s['base_stat'];
    }
    return stats;
  }

  List<String> _getTypes(Map<String, dynamic> data) {
    return (data['types'] as List).map((t) {
      final n = t['type']['name'] as String;
      return n[0].toUpperCase() + n.substring(1);
    }).toList();
  }

  int _getBST(Map<String, dynamic> data) {
    return (data['stats'] as List).fold(0, (sum, s) => sum + (s['base_stat'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Pokemon'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSelector(1, _pokemon1)),
                      const SizedBox(width: 8),
                      const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSelector(2, _pokemon2)),
                    ],
                  ),
                  if (_pokemon1 != null && _pokemon2 != null) ...[
                    const SizedBox(height: 24),
                    _buildComparison(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSelector(int slot, Map<String, dynamic>? data) {
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (v) {
            if (v.text.isEmpty) return const Iterable.empty();
            return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(8);
          },
          onSelected: (v) => _loadPokemon(v, slot),
          fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
            controller: ctrl, focusNode: focus,
            decoration: InputDecoration(
              hintText: 'Pokemon $slot',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (data != null) ...[
          const SizedBox(height: 8),
          Text(_capitalize(data['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _getTypes(data).map((t) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.typeColors[t], borderRadius: BorderRadius.circular(6)),
              child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10)),
            )).toList(),
          ),
          Text('BST: ${_getBST(data)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ],
    );
  }

  Widget _buildComparison() {
    final stats1 = _getStats(_pokemon1!);
    final stats2 = _getStats(_pokemon2!);
    final statNames = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Base Stat Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...statNames.map((stat) {
              final val1 = stats1[stat] ?? 0;
              final val2 = stats2[stat] ?? 0;
              final max = 255.0;
              final isP1Higher = val1 > val2;
              final isEqual = val1 == val2;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(stat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text('$val1', textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold,
                                  color: isP1Higher ? Colors.green : isEqual ? null : Colors.red, fontSize: 12)),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(height: 14, decoration: BoxDecoration(
                                color: Colors.grey.shade200, borderRadius: BorderRadius.circular(7))),
                              FractionallySizedBox(
                                widthFactor: val1 / max,
                                child: Container(height: 14, decoration: BoxDecoration(
                                  color: Colors.blue.shade400, borderRadius: BorderRadius.circular(7))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(height: 14, decoration: BoxDecoration(
                                color: Colors.grey.shade200, borderRadius: BorderRadius.circular(7))),
                              FractionallySizedBox(
                                widthFactor: val2 / max,
                                child: Container(height: 14, decoration: BoxDecoration(
                                  color: Colors.orange.shade400, borderRadius: BorderRadius.circular(7))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 30,
                          child: Text('$val2',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                  color: !isP1Higher && !isEqual ? Colors.green : isEqual ? null : Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_getBST(_pokemon1!)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Total: ${_getBST(_pokemon2!)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
