import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../services/breeding_service.dart';

class BreedingHelperScreen extends StatefulWidget {
  const BreedingHelperScreen({Key? key}) : super(key: key);

  @override
  State<BreedingHelperScreen> createState() => _BreedingHelperScreenState();
}

class _BreedingHelperScreenState extends State<BreedingHelperScreen> {
  List<String> _pokemonNames = [];
  String? _pokemon1;
  String? _pokemon2;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _eggMoves1 = [];
  List<Map<String, dynamic>> _eggMoves2 = [];
  bool _isLoading = true;
  bool _isChecking = false;

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

  Future<void> _checkCompatibility() async {
    if (_pokemon1 == null || _pokemon2 == null) return;
    setState(() => _isChecking = true);

    try {
      final result = await BreedingService.checkCompatibility(_pokemon1!, _pokemon2!);
      final moves1 = await BreedingService.getEggMoves(_pokemon1!);
      final moves2 = await BreedingService.getEggMoves(_pokemon2!);

      setState(() {
        _result = result;
        _eggMoves1 = moves1;
        _eggMoves2 = moves2;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _result = {'compatible': false, 'reason': 'Error: $e'};
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breeding Helper'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBreedingGuide(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Compatibility Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 12),
                          const Text('Parent 1'),
                          const SizedBox(height: 4),
                          Autocomplete<String>(
                            optionsBuilder: (v) {
                              if (v.text.isEmpty) return const Iterable.empty();
                              return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                            },
                            onSelected: (v) => setState(() => _pokemon1 = v),
                            fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                              controller: ctrl, focusNode: focus,
                              decoration: const InputDecoration(hintText: 'Search...', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Parent 2'),
                          const SizedBox(height: 4),
                          Autocomplete<String>(
                            optionsBuilder: (v) {
                              if (v.text.isEmpty) return const Iterable.empty();
                              return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                            },
                            onSelected: (v) => setState(() => _pokemon2 = v),
                            fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                              controller: ctrl, focusNode: focus,
                              decoration: const InputDecoration(hintText: 'Search...', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isChecking ? null : _checkCompatibility,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: _isChecking
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Check Compatibility', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: _result!['compatible'] == true ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              _result!['compatible'] == true ? Icons.check_circle : Icons.cancel,
                              color: _result!['compatible'] == true ? Colors.green : Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _result!['compatible'] == true ? 'Compatible!' : 'Not Compatible',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20,
                                color: _result!['compatible'] == true ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_result!['reason'] ?? ''),
                            if (_result!['eggGroups1'] != null) ...[
                              const SizedBox(height: 8),
                              Text('${_capitalize(_pokemon1!)}: ${(_result!['eggGroups1'] as List).map(_formatEggGroup).join(", ")}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('${_capitalize(_pokemon2!)}: ${(_result!['eggGroups2'] as List).map(_formatEggGroup).join(", ")}',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_eggMoves1.isNotEmpty || _eggMoves2.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (_eggMoves1.isNotEmpty)
                      _buildEggMovesCard(_capitalize(_pokemon1!), _eggMoves1),
                    if (_eggMoves2.isNotEmpty)
                      _buildEggMovesCard(_capitalize(_pokemon2!), _eggMoves2),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEggMovesCard(String name, List<Map<String, dynamic>> moves) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Egg Moves for $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: moves.map((m) => Chip(
                label: Text(m['name'], style: const TextStyle(fontSize: 11)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingGuide() {
    return Card(
      color: Colors.blue.shade50,
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.menu_book, color: Colors.blue),
          title: const Text('How Breeding Works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          subtitle: const Text('Tap to learn the rules', style: TextStyle(fontSize: 12, color: Colors.blue)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _guideSection(
                    'Compatibility Rules',
                    'Two Pokemon can breed if they share at least one Egg Group. '
                    'You need one male and one female. The baby is always the same species as the mother '
                    '(or the non-Ditto parent).',
                  ),
                  _guideSection(
                    'Ditto',
                    'Ditto can breed with any Pokemon except those in the "Undiscovered" egg group. '
                    'Ditto is essential for breeding genderless Pokemon (like Magnemite or Staryu). '
                    'When breeding with Ditto, the offspring is always the other parent\'s species.',
                  ),
                  _guideSection(
                    'Undiscovered Egg Group',
                    'Pokemon in the Undiscovered group (most baby Pokemon and legendaries) '
                    'cannot breed at all, not even with Ditto.',
                  ),
                  _guideSection(
                    'Ability Inheritance',
                    '• The mother has an 80% chance to pass her ability to offspring.\n'
                    '• Hidden Abilities can only be inherited if a parent has the HA.\n'
                    '• Females pass HA with a 60% chance.\n'
                    '• Males/genderless can only pass HA when breeding with Ditto (60% chance).\n'
                    '• Regular abilities: if the mother has ability slot 1, there\'s an 80% chance the baby gets slot 1 and 20% for slot 2.',
                  ),
                  _guideSection(
                    'Nature Inheritance',
                    'Give a parent an Everstone to guarantee the baby inherits that parent\'s Nature. '
                    'If both parents hold Everstones, it\'s a 50/50 which Nature is passed.',
                  ),
                  _guideSection(
                    'IV Inheritance',
                    'Normally, 3 random IVs are inherited from the parents combined 12 stats. '
                    'If either parent holds a Destiny Knot, 5 IVs are inherited instead. '
                    'Power items (Power Bracer, Belt, etc.) guarantee the corresponding stat is one of the inherited IVs.',
                  ),
                  _guideSection(
                    'Egg Moves',
                    'Egg moves are special moves a Pokemon can only learn through breeding. '
                    'The father (or either parent in Gen 9+) passes egg moves to the baby. '
                    'In Scarlet/Violet, you can also transfer egg moves between two Pokemon '
                    'of the same species using a Mirror Herb at a picnic.',
                  ),
                  _guideSection(
                    'Pokeball Inheritance',
                    'The mother\'s Pokeball is passed to the offspring. When breeding with Ditto, '
                    'the non-Ditto parent\'s ball is used. Master Balls and Cherish Balls cannot be inherited.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4)),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  String _formatEggGroup(dynamic g) => (g as String).split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
