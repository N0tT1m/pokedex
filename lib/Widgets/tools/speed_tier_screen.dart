import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../services/iv_calculator_service.dart';
import '../../theme/app_theme.dart';

class SpeedTierScreen extends StatefulWidget {
  const SpeedTierScreen({Key? key}) : super(key: key);

  @override
  State<SpeedTierScreen> createState() => _SpeedTierScreenState();
}

class _SpeedTierScreenState extends State<SpeedTierScreen> {
  List<Map<String, dynamic>> _speedList = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  int _showLevel = 50;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadSpeeds();
  }

  Future<void> _loadSpeeds() async {
    try {
      final pokemonList = await PokeApiService.getPokemonList(limit: 500);
      final List<Map<String, dynamic>> speeds = [];
      final items = pokemonList.take(500).toList();

      // Process in batches of 50 to avoid sequential API calls
      for (var i = 0; i < items.length; i += 50) {
        final batch = items.skip(i).take(50).toList();
        final results = await Future.wait(
          batch.map((p) async {
            try {
              final data = await PokeApiService.getPokemon(p['name']);
              final stats = data['stats'] as List;
              int baseSpeed = 0;
              for (var s in stats) {
                if (s['stat']['name'] == 'speed') {
                  baseSpeed = s['base_stat'];
                  break;
                }
              }
              final types = (data['types'] as List).map((t) {
                final n = t['type']['name'] as String;
                return n[0].toUpperCase() + n.substring(1);
              }).toList();

              final id = data['id'];

              return <String, dynamic>{
                'name': _capitalize(p['name']),
                'baseSpeed': baseSpeed,
                'types': types,
                'id': id,
                'image': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
              };
            } catch (_) {
              return null;
            }
          }),
        );
        speeds.addAll(results.whereType<Map<String, dynamic>>());
      }

      speeds.sort((a, b) => (b['baseSpeed'] as int).compareTo(a['baseSpeed'] as int));

      if (mounted) {
        setState(() {
          _speedList = speeds;
          _filtered = speeds;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _speedList.where((p) {
        if (_filterType != null) {
          final types = p['types'] as List;
          return types.contains(_filterType);
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Tiers'), backgroundColor: Colors.red),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading speed data...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: [
                // Controls
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _showLevel,
                          decoration: const InputDecoration(
                            labelText: 'Level', border: OutlineInputBorder(), isDense: true),
                          items: [1, 5, 10, 25, 50, 100].map((l) =>
                              DropdownMenuItem(value: l, child: Text('Lv. $l'))).toList(),
                          onChanged: (v) => setState(() => _showLevel = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _filterType,
                          decoration: const InputDecoration(
                            labelText: 'Type', border: OutlineInputBorder(), isDense: true),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All')),
                            ...['Fire', 'Water', 'Grass', 'Electric', 'Dragon', 'Psychic', 'Dark', 'Steel', 'Fairy', 'Fighting', 'Flying', 'Ghost', 'Ice', 'Ground', 'Rock', 'Bug', 'Poison', 'Normal'].map((t) =>
                                DropdownMenuItem(value: t, child: Text(t))),
                          ],
                          onChanged: (v) {
                            _filterType = v;
                            _applyFilter();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${_filtered.length} Pokemon', style: const TextStyle(color: Colors.white70)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final p = _filtered[index];
                      final baseSpeed = p['baseSpeed'] as int;
                      final types = p['types'] as List;

                      // Calculate actual speed at level with 0 EVs and 252 EVs
                      final minSpeed = IVCalculatorService.calculateSingleStat(
                          baseStat: baseSpeed, iv: 31, ev: 0, level: _showLevel, natureModifier: 1.0, isHP: false);
                      final maxSpeed = IVCalculatorService.calculateSingleStat(
                          baseStat: baseSpeed, iv: 31, ev: 252, level: _showLevel, natureModifier: 1.1, isHP: false);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(p['image']),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        title: Row(
                          children: [
                            Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 4),
                            ...types.map((t) => Container(
                              margin: const EdgeInsets.only(left: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppTheme.typeColors[t], borderRadius: BorderRadius.circular(4)),
                              child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 8)),
                            )),
                          ],
                        ),
                        subtitle: Text('Base: $baseSpeed | Lv.$_showLevel: $minSpeed-$maxSpeed', style: const TextStyle(fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSpeedColor(baseSpeed),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$baseSpeed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Color _getSpeedColor(int speed) {
    if (speed >= 130) return Colors.green;
    if (speed >= 100) return Colors.lightGreen;
    if (speed >= 80) return Colors.orange;
    if (speed >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
