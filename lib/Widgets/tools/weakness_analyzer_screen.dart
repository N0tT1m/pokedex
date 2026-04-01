import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../services/type_effectiveness_service.dart';
import '../../services/coverage_analyzer_service.dart';
import '../../theme/app_theme.dart';
import '../pokemon/pokemon_detail_sheet.dart';

class WeaknessAnalyzerScreen extends StatefulWidget {
  const WeaknessAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<WeaknessAnalyzerScreen> createState() => _WeaknessAnalyzerScreenState();
}

class _WeaknessAnalyzerScreenState extends State<WeaknessAnalyzerScreen> {
  List<String> _pokemonNames = [];
  List<Map<String, dynamic>> _team = []; // {name, types: [String]}
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPokemonList();
  }

  Future<void> _loadPokemonList() async {
    try {
      final list = await PokeApiService.getPokemonList(limit: 1025);
      setState(() {
        _pokemonNames = list.map((p) => p['name'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPokemon(String name) async {
    if (_team.length >= 6) return;
    try {
      final data = await PokeApiService.getPokemon(name.toLowerCase());
      final types = (data['types'] as List).map((t) {
        final n = t['type']['name'] as String;
        return n[0].toUpperCase() + n.substring(1);
      }).toList();

      setState(() {
        _team.add({'name': name, 'types': types});
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final teamTypes = _team.map((m) => List<String>.from(m['types'])).toList();
    final weaknesses = _team.isNotEmpty ? CoverageAnalyzerService.analyzeDefensiveWeaknesses(teamTypes) : <String, int>{};
    final resistances = _team.isNotEmpty ? CoverageAnalyzerService.analyzeDefensiveResistances(teamTypes) : <String, int>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Team Weakness Analyzer'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Pokemon (max 6):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_team.length < 6)
                    Autocomplete<String>(
                      optionsBuilder: (v) {
                        if (v.text.isEmpty) return const Iterable.empty();
                        return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                      },
                      onSelected: _addPokemon,
                      fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                        controller: ctrl, focusNode: focus,
                        decoration: InputDecoration(
                          hintText: 'Search Pokemon...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Team display
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _team.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final mon = entry.value;
                      return GestureDetector(
                        onTap: () => showPokemonDetailSheet(context, mon['name']),
                        child: Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_capitalize(mon['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            ...(mon['types'] as List).map((t) => Container(
                              margin: const EdgeInsets.only(left: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.typeColors[t], borderRadius: BorderRadius.circular(4)),
                              child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 9)),
                            )),
                          ],
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _team.removeAt(idx)),
                      ),
                      );
                    }).toList(),
                  ),
                  if (_team.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Defensive Coverage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    _buildTypeGrid(weaknesses, resistances),
                    const SizedBox(height: 24),
                    // Shared weaknesses warning
                    if (weaknesses.entries.where((e) => e.value >= 3).isNotEmpty) ...[
                      Card(
                        color: Colors.red.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Shared Weaknesses', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...weaknesses.entries.where((e) => e.value >= 3).map((e) =>
                                  Text('${e.key}: ${e.value}/${_team.length} team members weak',
                                      style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTypeGrid(Map<String, int> weaknesses, Map<String, int> resistances) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: TypeEffectivenessService.allTypes.map((type) {
        final weak = weaknesses[type] ?? 0;
        final resist = resistances[type] ?? 0;
        final typeColor = AppTheme.typeColors[type] ?? Colors.grey;

        String label;
        IconData icon;
        Color badgeColor;
        if (weak >= 3) {
          label = '$weak weak';
          icon = Icons.error;
          badgeColor = Colors.red.shade700;
        } else if (weak >= 1) {
          label = '$weak weak';
          icon = Icons.warning_amber;
          badgeColor = Colors.orange.shade700;
        } else if (resist >= 3) {
          label = '$resist resist';
          icon = Icons.shield;
          badgeColor = Colors.green.shade700;
        } else if (resist >= 1) {
          label = '$resist resist';
          icon = Icons.shield_outlined;
          badgeColor = Colors.green;
        } else {
          label = 'neutral';
          icon = Icons.remove;
          badgeColor = Colors.grey;
        }

        return Container(
          decoration: BoxDecoration(
            color: typeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 10, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(label, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
