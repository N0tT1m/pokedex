import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';


class CompetitiveSetsScreen extends StatefulWidget {
  const CompetitiveSetsScreen({Key? key}) : super(key: key);

  @override
  State<CompetitiveSetsScreen> createState() => _CompetitiveSetsScreenState();
}

class _CompetitiveSetsScreenState extends State<CompetitiveSetsScreen> {
  List<String> _pokemonNames = [];
  bool _isLoading = true;
  String? _selectedPokemon;
  Map<String, dynamic>? _pokemonData;

  // Common competitive sets (hardcoded Smogon-style data)
  static const Map<String, List<Map<String, dynamic>>> _sets = {
    'garchomp': [
      {'name': 'Swords Dance', 'nature': 'Jolly', 'ability': 'Rough Skin', 'item': 'Scale Shot',
       'evs': '252 Atk / 4 Def / 252 Spe', 'moves': ['Swords Dance', 'Earthquake', 'Scale Shot', 'Stone Edge']},
      {'name': 'Choice Scarf', 'nature': 'Jolly', 'ability': 'Rough Skin', 'item': 'Choice Scarf',
       'evs': '252 Atk / 4 Def / 252 Spe', 'moves': ['Earthquake', 'Outrage', 'Stone Edge', 'Fire Fang']},
    ],
    'dragapult': [
      {'name': 'Physical Attacker', 'nature': 'Adamant', 'ability': 'Clear Body', 'item': 'Choice Band',
       'evs': '252 Atk / 4 SpD / 252 Spe', 'moves': ['Dragon Darts', 'Phantom Force', 'U-turn', 'Sucker Punch']},
      {'name': 'Special Attacker', 'nature': 'Timid', 'ability': 'Infiltrator', 'item': 'Choice Specs',
       'evs': '252 SpA / 4 SpD / 252 Spe', 'moves': ['Shadow Ball', 'Draco Meteor', 'Fire Blast', 'U-turn']},
    ],
    'tyranitar': [
      {'name': 'Dragon Dance', 'nature': 'Jolly', 'ability': 'Sand Stream', 'item': 'Leftovers',
       'evs': '252 Atk / 4 Def / 252 Spe', 'moves': ['Dragon Dance', 'Stone Edge', 'Crunch', 'Earthquake']},
    ],
    'dragonite': [
      {'name': 'Dragon Dance', 'nature': 'Adamant', 'ability': 'Multiscale', 'item': 'Lum Berry',
       'evs': '252 Atk / 4 Def / 252 Spe', 'moves': ['Dragon Dance', 'Outrage', 'Extreme Speed', 'Earthquake']},
    ],
    'gengar': [
      {'name': 'Nasty Plot', 'nature': 'Timid', 'ability': 'Cursed Body', 'item': 'Life Orb',
       'evs': '252 SpA / 4 SpD / 252 Spe', 'moves': ['Nasty Plot', 'Shadow Ball', 'Sludge Bomb', 'Focus Blast']},
    ],
    'gyarados': [
      {'name': 'Dragon Dance', 'nature': 'Jolly', 'ability': 'Moxie', 'item': 'Sitrus Berry',
       'evs': '252 Atk / 4 Def / 252 Spe', 'moves': ['Dragon Dance', 'Waterfall', 'Earthquake', 'Ice Fang']},
    ],
    'lucario': [
      {'name': 'Swords Dance', 'nature': 'Jolly', 'ability': 'Inner Focus', 'item': 'Life Orb',
       'evs': '252 Atk / 4 SpD / 252 Spe', 'moves': ['Swords Dance', 'Close Combat', 'Bullet Punch', 'Crunch']},
      {'name': 'Special Attacker', 'nature': 'Timid', 'ability': 'Inner Focus', 'item': 'Life Orb',
       'evs': '252 SpA / 4 SpD / 252 Spe', 'moves': ['Nasty Plot', 'Aura Sphere', 'Flash Cannon', 'Vacuum Wave']},
    ],
    'scizor': [
      {'name': 'Swords Dance', 'nature': 'Adamant', 'ability': 'Technician', 'item': 'Life Orb',
       'evs': '252 Atk / 4 Def / 252 Spe', 'moves': ['Swords Dance', 'Bullet Punch', 'Bug Bite', 'Superpower']},
      {'name': 'Choice Band', 'nature': 'Adamant', 'ability': 'Technician', 'item': 'Choice Band',
       'evs': '248 HP / 252 Atk / 8 SpD', 'moves': ['Bullet Punch', 'U-turn', 'Superpower', 'Knock Off']},
    ],
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

  Future<void> _selectPokemon(String name) async {
    try {
      final data = await PokeApiService.getPokemon(name.toLowerCase());
      setState(() {
        _selectedPokemon = name;
        _pokemonData = data;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Competitive Sets'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search Pokemon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return const Iterable.empty();
                      return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                    },
                    onSelected: _selectPokemon,
                    fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                      controller: ctrl, focusNode: focus,
                      decoration: InputDecoration(
                        hintText: 'Search Pokemon...', prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_selectedPokemon != null) ...[
                    const SizedBox(height: 16),
                    Text(_capitalize(_selectedPokemon!),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 12),
                    if (_sets.containsKey(_selectedPokemon!.toLowerCase()))
                      ..._sets[_selectedPokemon!.toLowerCase()]!.map(_buildSetCard)
                    else
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No competitive sets available for this Pokemon.\n\n'
                              'Try popular Pokemon like Garchomp, Dragonite, Tyranitar, Gengar, Gyarados, Lucario, Scizor, or Dragapult.'),
                        ),
                      ),
                  ],
                  if (_selectedPokemon == null) ...[
                    const SizedBox(height: 24),
                    const Text('Popular Pokemon with Sets:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sets.keys.map((name) => ActionChip(
                        label: Text(_capitalize(name)),
                        onPressed: () => _selectPokemon(name),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSetCard(Map<String, dynamic> set) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(set['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _row('Nature', set['nature']),
            _row('Ability', set['ability']),
            _row('Item', set['item']),
            _row('EVs', set['evs']),
            const SizedBox(height: 8),
            const Text('Moves:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...((set['moves'] as List).map((m) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('- $m'),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
