import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

// Map of Pokemon that need a form suffix for the /pokemon/ endpoint
const _defaultForms = <String, String>{
  'giratina': 'giratina-altered',
  'shaymin': 'shaymin-land',
  'deoxys': 'deoxys-normal',
  'wormadam': 'wormadam-plant',
  'basculin': 'basculin-red-striped',
  'darmanitan': 'darmanitan-standard',
  'tornadus': 'tornadus-incarnate',
  'thundurus': 'thundurus-incarnate',
  'landorus': 'landorus-incarnate',
  'keldeo': 'keldeo-ordinary',
  'meloetta': 'meloetta-aria',
  'meowstic': 'meowstic-male',
  'aegislash': 'aegislash-shield',
  'pumpkaboo': 'pumpkaboo-average',
  'gourgeist': 'gourgeist-average',
  'oricorio': 'oricorio-baile',
  'lycanroc': 'lycanroc-midday',
  'wishiwashi': 'wishiwashi-solo',
  'minior': 'minior-red-meteor',
  'mimikyu': 'mimikyu-disguised',
  'toxtricity': 'toxtricity-amped',
  'eiscue': 'eiscue-ice',
  'indeedee': 'indeedee-male',
  'morpeko': 'morpeko-full-belly',
  'urshifu': 'urshifu-single-strike',
  'basculegion': 'basculegion-male',
  'enamorus': 'enamorus-incarnate',
  'oinkologne': 'oinkologne-male',
  'palafin': 'palafin-zero',
  'tatsugiri': 'tatsugiri-curly',
  'dudunsparce': 'dudunsparce-two-segment',
  'gimmighoul': 'gimmighoul-full',
  'ogerpon': 'ogerpon-teal-mask',
  'zygarde': 'zygarde-50',
};

/// Shows a bottom sheet with Pokemon details loaded from PokeAPI.
/// [pokemonName] should be the Pokemon's name in API format (lowercase, hyphenated).
void showPokemonDetailSheet(BuildContext context, String pokemonName) {
  var apiName = pokemonName.toLowerCase().replaceAll(' ', '-').replaceAll('.', '').replaceAll("'", '');

  // Use default form name if this Pokemon requires it
  if (_defaultForms.containsKey(apiName)) {
    apiName = _defaultForms[apiName]!;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PokemonDetailSheetContent(apiName: apiName),
  );
}

class _PokemonDetailSheetContent extends StatefulWidget {
  final String apiName;
  const _PokemonDetailSheetContent({required this.apiName});

  @override
  State<_PokemonDetailSheetContent> createState() => _PokemonDetailSheetContentState();
}

class _PokemonDetailSheetContentState extends State<_PokemonDetailSheetContent> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _typeDefenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await PokeApiService.getPokemon(widget.apiName);
      List<Map<String, dynamic>> defenses = [];
      try {
        defenses = await PokeApiService.getPokemonTypeDefenses(widget.apiName);
      } catch (_) {}
      if (mounted) setState(() { _data = data; _typeDefenses = defenses; _isLoading = false; });
    } catch (e) {
      final baseName = widget.apiName.split('-').first;
      if (baseName != widget.apiName) {
        try {
          final data = await PokeApiService.getPokemon(baseName);
          List<Map<String, dynamic>> defenses = [];
          try {
            defenses = await PokeApiService.getPokemonTypeDefenses(baseName);
          } catch (_) {}
          if (mounted) setState(() { _data = data; _typeDefenses = defenses; _isLoading = false; });
          return;
        } catch (_) {}
      }
      if (mounted) setState(() { _error = 'Could not load Pokemon data'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
        }

        final data = _data!;
        final name = _capitalize(data['name'] as String);
        final types = (data['types'] as List).map((t) {
          final n = t['type']['name'] as String;
          return n[0].toUpperCase() + n.substring(1);
        }).toList();
        final stats = <String, int>{};
        for (var s in data['stats']) {
          final n = s['stat']['name'] as String;
          final mapped = _statNames[n];
          if (mapped != null) stats[mapped] = s['base_stat'] as int;
        }
        final abilities = (data['abilities'] as List).map((a) {
          final n = (a['ability']['name'] as String);
          final hidden = a['is_hidden'] == true;
          return '${_capitalize(n)}${hidden ? ' (Hidden)' : ''}';
        }).toList();
        final sprite = data['sprites']?['other']?['official-artwork']?['front_default']
            ?? data['sprites']?['front_default'] ?? '';
        final bst = (data['stats'] as List).fold<int>(0, (sum, s) => sum + (s['base_stat'] as int));

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (sprite.isNotEmpty)
              Center(
                child: Image.network(sprite, height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 80)),
              ),
            const SizedBox(height: 8),
            Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: types.map((t) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.typeColors[t] ?? Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Abilities
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Abilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    ...abilities.map((a) => Text(a)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('BST: $bst', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...stats.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(width: 65, child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          SizedBox(width: 32, child: Text('${e.value}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: e.value / 255,
                                backgroundColor: Colors.grey.shade200,
                                color: _statColor(e.value),
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            if (_typeDefenses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Type Defenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ..._buildDefenseSections(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildDefenseSections() {
    final weaknesses = _typeDefenses.where((t) => (t['multiplier'] as num) > 1).toList();
    final resistances = _typeDefenses.where((t) => (t['multiplier'] as num) < 1 && (t['multiplier'] as num) > 0).toList();
    final immunities = _typeDefenses.where((t) => (t['multiplier'] as num) == 0).toList();

    final List<Widget> widgets = [];

    if (weaknesses.isNotEmpty) {
      widgets.add(Text('Weak to:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)));
      widgets.add(const SizedBox(height: 4));
      widgets.add(Wrap(
        spacing: 4, runSpacing: 4,
        children: weaknesses.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text('${t['type_name']} ${t['multiplier']}x', style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
        )).toList(),
      ));
      widgets.add(const SizedBox(height: 6));
    }

    if (resistances.isNotEmpty) {
      widgets.add(Text('Resists:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)));
      widgets.add(const SizedBox(height: 4));
      widgets.add(Wrap(
        spacing: 4, runSpacing: 4,
        children: resistances.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text('${t['type_name']} ${t['multiplier']}x', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
        )).toList(),
      ));
      widgets.add(const SizedBox(height: 6));
    }

    if (immunities.isNotEmpty) {
      widgets.add(Text('Immune to:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)));
      widgets.add(const SizedBox(height: 4));
      widgets.add(Wrap(
        spacing: 4, runSpacing: 4,
        children: immunities.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text('${t['type_name']}', style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
        )).toList(),
      ));
    }

    return widgets;
  }

  Color _statColor(int val) {
    if (val >= 130) return Colors.green.shade600;
    if (val >= 100) return Colors.green;
    if (val >= 70) return Colors.amber;
    if (val >= 50) return Colors.orange;
    return Colors.red;
  }

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  static const _statNames = {
    'hp': 'HP', 'attack': 'Attack', 'defense': 'Defense',
    'special-attack': 'Sp. Atk', 'special-defense': 'Sp. Def', 'speed': 'Speed',
  };
}
