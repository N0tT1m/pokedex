import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

class StatRankerScreen extends StatefulWidget {
  const StatRankerScreen({Key? key}) : super(key: key);

  @override
  State<StatRankerScreen> createState() => _StatRankerScreenState();
}

class _StatRankerScreenState extends State<StatRankerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPokemon = [];
  List<Map<String, dynamic>> _filteredPokemon = [];
  String _sortBy = 'BST';
  String? _filterType;
  int _minStat = 0;
  bool _loadingDetails = false;

  static const _statKeys = {
    'HP': 'hp', 'Attack': 'attack', 'Defense': 'defense',
    'Sp. Atk': 'special-attack', 'Sp. Def': 'special-defense',
    'Speed': 'speed', 'BST': 'bst',
  };

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  Future<void> _loadPokemon() async {
    setState(() => _loadingDetails = true);
    try {
      final list = await PokeApiService.getPokemonList(limit: 1025);

      // Load stats for first 200 Pokemon as a starter set
      final pokemon = <Map<String, dynamic>>[];
      for (int i = 1; i <= 1025; i++) {
        try {
          final data = await PokeApiService.getPokemon(i.toString());
          final stats = <String, int>{};
          int bst = 0;
          for (var s in data['stats']) {
            stats[s['stat']['name']] = s['base_stat'] as int;
            bst += s['base_stat'] as int;
          }
          stats['bst'] = bst;

          final types = (data['types'] as List)
              .map((t) => (t['type']['name'] as String))
              .map((t) => t[0].toUpperCase() + t.substring(1))
              .toList();

          pokemon.add({
            'id': data['id'],
            'name': data['name'],
            'stats': stats,
            'types': types,
            'bst': bst,
          });
        } catch (_) {
          continue;
        }
        // Load in batches and update UI periodically
        if (i % 50 == 0) {
          setState(() {
            _allPokemon = List.from(pokemon);
            _applyFilters();
            _isLoading = false;
          });
        }
      }

      setState(() {
        _allPokemon = pokemon;
        _applyFilters();
        _isLoading = false;
        _loadingDetails = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _loadingDetails = false; });
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allPokemon);

    if (_filterType != null) {
      filtered = filtered.where((p) => (p['types'] as List).contains(_filterType)).toList();
    }

    if (_minStat > 0) {
      final statKey = _statKeys[_sortBy] ?? 'bst';
      filtered = filtered.where((p) {
        final stats = p['stats'] as Map<String, int>;
        return (stats[statKey] ?? p['bst'] ?? 0) >= _minStat;
      }).toList();
    }

    // Sort
    final statKey = _statKeys[_sortBy] ?? 'bst';
    filtered.sort((a, b) {
      final aStats = a['stats'] as Map<String, int>;
      final bStats = b['stats'] as Map<String, int>;
      final aVal = statKey == 'bst' ? (a['bst'] ?? 0) : (aStats[statKey] ?? 0);
      final bVal = statKey == 'bst' ? (b['bst'] ?? 0) : (bStats[statKey] ?? 0);
      return bVal.compareTo(aVal); // Descending
    });

    _filteredPokemon = filtered;
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stat Ranker'), backgroundColor: Colors.red),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statKeys.keys.map((stat) =>
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text(stat, style: const TextStyle(fontSize: 12)),
                                selected: _sortBy == stat,
                                onSelected: (v) {
                                  setState(() { _sortBy = stat; _applyFilters(); });
                                },
                              ),
                            )).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: const Text('All', style: TextStyle(fontSize: 11)),
                                selected: _filterType == null,
                                onSelected: (v) {
                                  setState(() { _filterType = null; _applyFilters(); });
                                },
                              ),
                            ),
                            ...['Fire', 'Water', 'Grass', 'Electric', 'Dragon', 'Steel',
                                'Fairy', 'Dark', 'Psychic', 'Fighting', 'Ghost', 'Ice',
                                'Rock', 'Ground', 'Flying', 'Poison', 'Bug', 'Normal']
                              .map((t) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ChoiceChip(
                                  label: Text(t, style: const TextStyle(fontSize: 11)),
                                  selected: _filterType == t,
                                  backgroundColor: AppTheme.typeColors[t]?.withOpacity(0.2),
                                  onSelected: (v) {
                                    setState(() { _filterType = v ? t : null; _applyFilters(); });
                                  },
                                ),
                              )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Min ${_sortBy}: $_minStat', style: const TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _minStat.toDouble(), min: 0, max: 255,
                        divisions: 51,
                        onChanged: (v) => setState(() { _minStat = v.toInt(); _applyFilters(); }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading && _allPokemon.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('${_filteredPokemon.length} Pokemon',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (_loadingDetails) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                  const Text(' loading...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPokemon.length,
              itemBuilder: (context, index) {
                final p = _filteredPokemon[index];
                final stats = p['stats'] as Map<String, int>;
                final types = p['types'] as List;
                final statKey = _statKeys[_sortBy] ?? 'bst';
                final displayStat = statKey == 'bst' ? p['bst'] : stats[statKey] ?? 0;

                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${p['id']}.png',
                          width: 28, height: 28,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  title: Text(_formatName(p['name']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Row(
                    children: [
                      ...types.map((t) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.typeColors[t], borderRadius: BorderRadius.circular(6)),
                        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10)),
                      )),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$displayStat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(_sortBy, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
