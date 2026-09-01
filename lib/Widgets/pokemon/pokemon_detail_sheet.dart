import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
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

String _resolveApiName(String pokemonName) {
  var apiName = pokemonName.toLowerCase().replaceAll(' ', '-').replaceAll('.', '').replaceAll("'", '');
  return _defaultForms[apiName] ?? apiName;
}

/// Shows a bottom sheet with Pokemon details.
void showPokemonDetailSheet(BuildContext context, String pokemonName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PokemonDetailSheetContent(apiName: _resolveApiName(pokemonName)),
  );
}

/// Full-page Pokemon detail screen for use with Navigator.push.
class PokemonDetailPage extends StatelessWidget {
  final String pokemonName;
  const PokemonDetailPage({Key? key, required this.pokemonName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiName = _resolveApiName(pokemonName);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          apiName.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' '),
        ),
      ),
      body: _PokemonDetailBody(apiName: apiName),
    );
  }
}

// ── Shared detail body ─────────────────────────────────────────────────────────

/// Loads and renders all Pokemon detail content as a scrollable ListView.
/// Used by both the bottom sheet and the full-page detail view.
class _PokemonDetailBody extends StatefulWidget {
  final String apiName;
  final ScrollController? scrollController;
  const _PokemonDetailBody({required this.apiName, this.scrollController});

  @override
  State<_PokemonDetailBody> createState() => _PokemonDetailBodyState();
}

class _PokemonDetailBodyState extends State<_PokemonDetailBody> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _typeDefenses = [];
  List<Map<String, dynamic>> _abilityDetails = []; // {name, description, isHidden}
  String _biology = '';
  List<Map<String, dynamic>> _heldItems = [];
  List<Map<String, dynamic>> _gameLocations = [];
  Map<String, dynamic>? _classification;
  Map<String, dynamic>? _goStats;
  List<Map<String, dynamic>> _contestStats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _loadForName(widget.apiName);
    } catch (_) {
      final baseName = widget.apiName.split('-').first;
      if (baseName != widget.apiName) {
        try {
          await _loadForName(baseName);
          return;
        } catch (_) {}
      }
      if (mounted) setState(() { _error = 'Could not load Pokemon data'; _isLoading = false; });
    }
  }

  Future<void> _loadForName(String name) async {
    final data = await PokeApiService.getPokemon(name);

    // Fetch all secondary data in parallel
    List<Map<String, dynamic>> defenses = [];
    String biology = '';
    List<Map<String, dynamic>> heldItems = [];
    List<Map<String, dynamic>> gameLocations = [];
    Map<String, dynamic>? classification;
    Map<String, dynamic>? goStats;
    List<Map<String, dynamic>> contestStats = [];

    await Future.wait([
      PokeApiService.getPokemonTypeDefenses(name)
          .then((v) => defenses = v)
          .catchError((_) => defenses),
      Requests.get('${PokeApiService.baseUrl}/pokemon/$name/biology').then((r) {
        if (r.statusCode == 200) biology = r.json()['biology'] as String? ?? '';
      }).catchError((_) {}),
      Requests.get('${PokeApiService.baseUrl}/pokemon/$name/held-items').then((r) {
        if (r.statusCode == 200) heldItems = List<Map<String, dynamic>>.from(r.json()['held_items'] ?? []);
      }).catchError((_) {}),
      Requests.get('${PokeApiService.baseUrl}/pokemon/$name/game-locations').then((r) {
        if (r.statusCode == 200) gameLocations = List<Map<String, dynamic>>.from(r.json()['locations'] ?? []);
      }).catchError((_) {}),
      Requests.get('${PokeApiService.baseUrl}/pokemon/$name/classification').then((r) {
        if (r.statusCode == 200) classification = Map<String, dynamic>.from(r.json());
      }).catchError((_) {}),
      Requests.get('${PokeApiService.baseUrl}/pokemon/$name/go').then((r) {
        if (r.statusCode == 200) goStats = Map<String, dynamic>.from(r.json());
      }).catchError((_) {}),
      Requests.get('${PokeApiService.baseUrl}/pokemon/$name/contest-stats').then((r) {
        if (r.statusCode == 200) contestStats = List<Map<String, dynamic>>.from(r.json()['contest_stats'] ?? []);
      }).catchError((_) {}),
    ]);

    // Fetch ability descriptions in parallel
    final rawAbilities = data['abilities'] as List? ?? [];
    final abilityDetails = await Future.wait(rawAbilities.map((a) async {
      final apiName = a['ability']['name'] as String;
      final isHidden = a['is_hidden'] == true;
      String desc = '';
      try {
        final r = await Requests.get('${PokeApiService.baseUrl}/ability/$apiName');
        if (r.statusCode == 200) {
          final entries = r.json()['effect_entries'] as List? ?? [];
          for (final e in entries) {
            if (e['language']?['name'] == 'en') {
              desc = e['short_effect'] as String? ?? '';
              break;
            }
          }
        }
      } catch (_) {}
      return {'name': _capitalize(apiName), 'description': desc, 'isHidden': isHidden};
    }));

    if (mounted) setState(() {
      _data = data;
      _typeDefenses = defenses;
      _abilityDetails = List<Map<String, dynamic>>.from(abilityDetails);
      _biology = biology;
      _heldItems = heldItems;
      _gameLocations = gameLocations;
      _classification = classification;
      _goStats = goStats;
      _contestStats = contestStats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    {
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
        final sprite = data['sprites']?['other']?['official-artwork']?['front_default']
            ?? data['sprites']?['front_default'] ?? '';
        final bst = (data['stats'] as List).fold<int>(0, (sum, s) => sum + (s['base_stat'] as int));

      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        children: [
            if (sprite.isNotEmpty)
              Center(
                child: Image.network(sprite, height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 80)),
              ),
            const SizedBox(height: 8),
            Center(child: Text('#${data['id']} $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
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
            // Wild Held Items (shown first, like the Pokedex detail)
            if (_heldItems.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wild Held Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ..._heldItems.map((h) {
                        final itemName = (h['item']?['name'] as String? ?? '').split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                        final game = h['game']?.toString() ?? '';
                        final rarity = h['rarity']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.backpack, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(itemName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                              if (rarity.isNotEmpty)
                                Text(rarity, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              if (game.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(game, style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Abilities with descriptions and HA badge
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Abilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    ..._abilityDetails.map((a) {
                      final isHidden = a['isHidden'] == true;
                      final abilityName = a['name'] as String;
                      final desc = a['description'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isHidden)
                              Container(
                                margin: const EdgeInsets.only(top: 1, right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  border: Border.all(color: Colors.purple, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('HA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(abilityName, style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isHidden ? Colors.purple : null,
                                  )),
                                  if (desc.isNotEmpty)
                                    Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
            if (_gameLocations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How to Obtain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ..._gameLocations.map((loc) {
                        final game = loc['game']?.toString() ?? '';
                        final location = loc['location']?.toString() ?? '';
                        final method = loc['method']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2, right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _methodColor(method).withOpacity(0.15),
                                  border: Border.all(color: _methodColor(method), width: 1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  method.isEmpty ? 'Wild' : method,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _methodColor(method)),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(game, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                    Text(location, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            if (_biology.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Biology', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(_biology, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
            if (_classification != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Classification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (_classification!['generation_introduced'] != null)
                            _infoBadge('Gen ${_classification!['generation_introduced']}', Colors.blue),
                          if (_classification!['color'] != null)
                            _infoBadge(_capitalize(_classification!['color']), Colors.blueGrey),
                          if (_classification!['shape'] != null)
                            _infoBadge(_capitalize(_classification!['shape']), Colors.teal),
                          if (_classification!['habitat'] != null)
                            _infoBadge(_capitalize(_classification!['habitat']), Colors.green),
                          if (_classification!['is_legendary'] == true)
                            _infoBadge('Legendary', Colors.amber.shade700),
                          if (_classification!['is_mythical'] == true)
                            _infoBadge('Mythical', Colors.purple),
                          if (_classification!['is_ultra_beast'] == true)
                            _infoBadge('Ultra Beast', Colors.deepOrange),
                          if (_classification!['is_baby'] == true)
                            _infoBadge('Baby', Colors.pink),
                          if (_classification!['is_paradox'] == true)
                            _infoBadge('Paradox', Colors.indigo),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_goStats != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pokemon GO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _goStatBox('Max CP', '${_goStats!['max_cp'] ?? '-'}')),
                          Expanded(child: _goStatBox('Attack', '${_goStats!['base_attack'] ?? '-'}')),
                          Expanded(child: _goStatBox('Defense', '${_goStats!['base_defense'] ?? '-'}')),
                          Expanded(child: _goStatBox('Stamina', '${_goStats!['base_stamina'] ?? '-'}')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_goStats!['buddy_distance_km'] != null)
                            _infoBadge('${_goStats!['buddy_distance_km']} km buddy', Colors.orange),
                          const SizedBox(width: 6),
                          if (_goStats!['shiny_available'] == true)
                            _infoBadge('Shiny available', Colors.amber),
                          const SizedBox(width: 6),
                          if (_goStats!['shadow_available'] == true)
                            _infoBadge('Shadow available', Colors.deepPurple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_contestStats.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contest Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      ..._contestStats.map((s) {
                        final type = _capitalize(s['contest_type'] as String? ?? '');
                        final appeal = s['appeal'] as int? ?? 0;
                        final jam = s['jam'] as int? ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(width: 80, child: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              Text('Appeal: $appeal', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 12),
                              Text('Jam: $jam', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
        ],
      );
    }
  }

  Widget _infoBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      border: Border.all(color: color, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _goStatBox(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ],
  );

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

  Color _methodColor(String method) {
    switch (method) {
      case 'Special':  return Colors.purple;
      case 'Roaming':  return Colors.deepPurple;
      case 'Event':    return Colors.orange;
      case 'Gift':     return Colors.green;
      case 'Fossil':   return Colors.brown;
      case 'Trade':    return Colors.blue;
      case 'Hatch':    return Colors.pink;
      case 'Wild':     return Colors.grey.shade600;
      default:         return Colors.grey.shade600;
    }
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

// ── Sheet wrapper (bottom sheet with drag handle) ─────────────────────────────

class _PokemonDetailSheetContent extends StatelessWidget {
  final String apiName;
  const _PokemonDetailSheetContent({required this.apiName});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(child: _PokemonDetailBody(apiName: apiName, scrollController: scrollController)),
          ],
        );
      },
    );
  }
}
