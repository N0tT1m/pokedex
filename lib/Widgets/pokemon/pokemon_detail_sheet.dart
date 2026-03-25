import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

/// Shows a bottom sheet with Pokemon details loaded from PokeAPI.
/// [pokemonName] should be the Pokemon's name in API format (lowercase, hyphenated).
void showPokemonDetailSheet(BuildContext context, String pokemonName) {
  final apiName = pokemonName.toLowerCase().replaceAll(' ', '-').replaceAll('.', '').replaceAll("'", '');

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
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
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
          ],
        );
      },
    );
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
