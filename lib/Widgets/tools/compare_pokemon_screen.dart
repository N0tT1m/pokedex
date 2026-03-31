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
  int _level1 = 50;
  int _level2 = 50;
  String _nature1 = 'Hardy';
  String _nature2 = 'Hardy';

  static const _statMap = {
    'hp': 'HP', 'attack': 'Attack', 'defense': 'Defense',
    'special-attack': 'Sp. Atk', 'special-defense': 'Sp. Def', 'speed': 'Speed'
  };

  static const _natures = <String, Map<String, double>>{
    'Hardy': {}, 'Docile': {}, 'Serious': {}, 'Bashful': {}, 'Quirky': {},
    'Lonely': {'Attack': 1.1, 'Defense': 0.9},
    'Brave': {'Attack': 1.1, 'Speed': 0.9},
    'Adamant': {'Attack': 1.1, 'Sp. Atk': 0.9},
    'Naughty': {'Attack': 1.1, 'Sp. Def': 0.9},
    'Bold': {'Defense': 1.1, 'Attack': 0.9},
    'Relaxed': {'Defense': 1.1, 'Speed': 0.9},
    'Impish': {'Defense': 1.1, 'Sp. Atk': 0.9},
    'Lax': {'Defense': 1.1, 'Sp. Def': 0.9},
    'Timid': {'Speed': 1.1, 'Attack': 0.9},
    'Hasty': {'Speed': 1.1, 'Defense': 0.9},
    'Jolly': {'Speed': 1.1, 'Sp. Atk': 0.9},
    'Naive': {'Speed': 1.1, 'Sp. Def': 0.9},
    'Modest': {'Sp. Atk': 1.1, 'Attack': 0.9},
    'Mild': {'Sp. Atk': 1.1, 'Defense': 0.9},
    'Quiet': {'Sp. Atk': 1.1, 'Speed': 0.9},
    'Rash': {'Sp. Atk': 1.1, 'Sp. Def': 0.9},
    'Calm': {'Sp. Def': 1.1, 'Attack': 0.9},
    'Gentle': {'Sp. Def': 1.1, 'Defense': 0.9},
    'Sassy': {'Sp. Def': 1.1, 'Speed': 0.9},
    'Careful': {'Sp. Def': 1.1, 'Sp. Atk': 0.9},
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

  int _calculateStat(int base, String statName, int level, String nature) {
    if (statName == 'HP') {
      return ((2 * base + 31) * level / 100).floor() + level + 10;
    }
    final mod = _natures[nature]?[statName] ?? 1.0;
    return (((2 * base + 31) * level / 100).floor() + 5) * mod ~/ 1;
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: slot == 1 ? _level1 : _level2,
                isExpanded: true,
                isDense: true,
                items: [1, 5, 10, 25, 50, 100].map((l) =>
                  DropdownMenuItem(value: l, child: Text('Lv $l', style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => setState(() {
                  if (slot == 1) _level1 = v!; else _level2 = v!;
                }),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: DropdownButton<String>(
                value: slot == 1 ? _nature1 : _nature2,
                isExpanded: true,
                isDense: true,
                items: _natures.keys.map((n) =>
                  DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => setState(() {
                  if (slot == 1) _nature1 = v!; else _nature2 = v!;
                }),
              ),
            ),
          ],
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
    final base1 = _getStats(_pokemon1!);
    final base2 = _getStats(_pokemon2!);
    final statNames = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Stat Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...statNames.map((stat) {
              final val1 = _calculateStat(base1[stat] ?? 0, stat, _level1, _nature1);
              final val2 = _calculateStat(base2[stat] ?? 0, stat, _level2, _nature2);
              final max = stat == 'HP' ? 714.0 : 614.0;
              final isP1Higher = val1 > val2;
              final isEqual = val1 == val2;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(stat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Base: ${base1[stat] ?? 0} / ${base2[stat] ?? 0}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 36,
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
                                widthFactor: (val1 / max).clamp(0.0, 1.0),
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
                                widthFactor: (val2 / max).clamp(0.0, 1.0),
                                child: Container(height: 14, decoration: BoxDecoration(
                                  color: Colors.orange.shade400, borderRadius: BorderRadius.circular(7))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 36,
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
