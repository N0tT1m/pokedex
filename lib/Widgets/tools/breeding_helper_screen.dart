import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../services/breeding_service.dart';

class BreedingHelperScreen extends StatefulWidget {
  const BreedingHelperScreen({Key? key}) : super(key: key);

  @override
  State<BreedingHelperScreen> createState() => _BreedingHelperScreenState();
}

class _BreedingHelperScreenState extends State<BreedingHelperScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> _pokemonNames = [];
  String? _pokemon1;
  String? _pokemon2;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _eggMoves1 = [];
  List<Map<String, dynamic>> _eggMoves2 = [];
  List<Map<String, dynamic>> _passableTo1 = [];
  List<Map<String, dynamic>> _passableTo2 = [];
  bool _isLoading = true;
  bool _isChecking = false;

  // SV tab state (reuses same fields but annotated for SV context)
  String? _svPokemon1;
  String? _svPokemon2;
  Map<String, dynamic>? _svResult;
  List<Map<String, dynamic>> _svEggMoves1 = [];
  List<Map<String, dynamic>> _svEggMoves2 = [];
  List<Map<String, dynamic>> _svPassableTo1 = [];
  List<Map<String, dynamic>> _svPassableTo2 = [];
  bool _svChecking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _checkCompatibility({bool sv = false}) async {
    final p1 = sv ? _svPokemon1 : _pokemon1;
    final p2 = sv ? _svPokemon2 : _pokemon2;
    if (p1 == null || p2 == null) return;
    if (sv) {
      setState(() => _svChecking = true);
    } else {
      setState(() => _isChecking = true);
    }

    try {
      final result = await BreedingService.checkCompatibility(p1, p2);
      final moves1 = await BreedingService.getEggMoves(p1);
      final moves2 = await BreedingService.getEggMoves(p2);
      final allMoves1 = await PokeApiService.getPokemonMoves(p1.toLowerCase());
      final allMoves2 = await PokeApiService.getPokemonMoves(p2.toLowerCase());

      final nativeMoves2 = allMoves2
          .where((m) {
            final method = (m['learn_method'] as String? ?? '').toLowerCase();
            return method == 'level-up' || method == 'tm' || method == 'tutor';
          })
          .map((m) => m['name'] as String)
          .toSet();
      final nativeMoves1 = allMoves1
          .where((m) {
            final method = (m['learn_method'] as String? ?? '').toLowerCase();
            return method == 'level-up' || method == 'tm' || method == 'tutor';
          })
          .map((m) => m['name'] as String)
          .toSet();

      final passableTo1 = moves1.where((m) => nativeMoves2.contains(m['apiName'])).toList();
      final passableTo2 = moves2.where((m) => nativeMoves1.contains(m['apiName'])).toList();

      setState(() {
        if (sv) {
          _svResult = result;
          _svEggMoves1 = moves1;
          _svEggMoves2 = moves2;
          _svPassableTo1 = passableTo1;
          _svPassableTo2 = passableTo2;
          _svChecking = false;
        } else {
          _result = result;
          _eggMoves1 = moves1;
          _eggMoves2 = moves2;
          _passableTo1 = passableTo1;
          _passableTo2 = passableTo2;
          _isChecking = false;
        }
      });
    } catch (e) {
      setState(() {
        if (sv) {
          _svResult = {'compatible': false, 'reason': 'Error: $e'};
          _svChecking = false;
        } else {
          _result = {'compatible': false, 'reason': 'Error: $e'};
          _isChecking = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breeding Helper'),
        backgroundColor: Colors.red,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Compatibility'),
            Tab(text: 'Scarlet/Violet'),
            Tab(text: 'Guide'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCompatibilityTab(),
                _buildSVTab(),
                _buildGuideTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Standard Compatibility ────────────────────────────────────────

  Widget _buildCompatibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Compatibility Check',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Works for all generations (Gen 1–8).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  const Text('Parent 1'),
                  const SizedBox(height: 4),
                  _buildAutocomplete(
                    onSelected: (v) => setState(() => _pokemon1 = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Parent 2'),
                  const SizedBox(height: 4),
                  _buildAutocomplete(
                    onSelected: (v) => setState(() => _pokemon2 = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : () => _checkCompatibility(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: _isChecking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Check Compatibility',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_result!, _pokemon1, _pokemon2),
          ],
          if (_result != null && (_eggMoves1.isNotEmpty || _eggMoves2.isNotEmpty)) ...[
            const SizedBox(height: 16),
            if (_passableTo1.isNotEmpty)
              _buildPassableMovesCard(
                '${_capitalize(_pokemon1!)} can inherit from ${_capitalize(_pokemon2!)}',
                _passableTo1, Colors.green.shade50,
              )
            else if (_eggMoves1.isNotEmpty)
              _buildNoPassableCard(_capitalize(_pokemon1!), _capitalize(_pokemon2!)),
            const SizedBox(height: 8),
            if (_passableTo2.isNotEmpty)
              _buildPassableMovesCard(
                '${_capitalize(_pokemon2!)} can inherit from ${_capitalize(_pokemon1!)}',
                _passableTo2, Colors.blue.shade50,
              )
            else if (_eggMoves2.isNotEmpty)
              _buildNoPassableCard(_capitalize(_pokemon2!), _capitalize(_pokemon1!)),
          ],
        ],
      ),
    );
  }

  // ── Tab 2: Scarlet/Violet ─────────────────────────────────────────────────

  Widget _buildSVTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Key SV differences callout
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.new_releases, color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 6),
                      Text('Scarlet/Violet Changes',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.purple.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _svChange(Icons.lunch_dining, 'Picnic Breeding',
                      'Breeding happens at Picnics instead of a Day Care / Nursery. '
                      'Set up a Picnic with both Pokémon in your party and wait — eggs appear in the basket.'),
                  _svChange(Icons.swap_horiz, 'Either Parent Passes Egg Moves',
                      'In Gen 9, both the father AND mother can pass egg moves to the offspring. '
                      'You no longer need the father to know the move.'),
                  _svChange(Icons.grass, 'Egg Power Sandwiches',
                      'Eat a sandwich with Egg Power to dramatically increase egg frequency. '
                      'Egg Power Lv.2 or Lv.3 from a specific type sandwich also makes the eggs share that Pokémon type.'),
                  _svChange(Icons.grass_outlined, 'Mirror Herb — No Breeding Required',
                      'Have a Pokémon hold a Mirror Herb, then place it in a Picnic with a same-species Pokémon '
                      'that knows the egg move. The Mirror Herb Pokémon copies the move without any breeding. '
                      'Works for males and genderless Pokémon too.'),
                  _svChange(Icons.egg_alt, 'Picnic Tips',
                      '• Keep walking or doing activities — eggs appear roughly every 30 seconds.\n'
                      '• The Pokémon must be out of their Poké Balls (in your party at the Picnic).\n'
                      '• Flame Body ability still halves hatching steps.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SV Compatibility Checker (same logic, SV-context labels)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SV Picnic Compatibility',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Egg group rules are the same as older games.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  const Text('Parent 1'),
                  const SizedBox(height: 4),
                  _buildAutocomplete(
                    onSelected: (v) => setState(() => _svPokemon1 = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Parent 2'),
                  const SizedBox(height: 4),
                  _buildAutocomplete(
                    onSelected: (v) => setState(() => _svPokemon2 = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _svChecking ? null : () => _checkCompatibility(sv: true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: _svChecking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Check SV Compatibility',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_svResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_svResult!, _svPokemon1, _svPokemon2, sv: true),
          ],
          if (_svResult != null && (_svEggMoves1.isNotEmpty || _svEggMoves2.isNotEmpty)) ...[
            const SizedBox(height: 16),
            // In SV, EITHER parent passes egg moves
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.egg, color: Colors.purple.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text('Egg Move Inheritance (SV)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('In Scarlet/Violet, either parent can pass egg moves.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_svPassableTo1.isNotEmpty)
              _buildPassableMovesCard(
                '${_capitalize(_svPokemon1!)} can inherit from ${_capitalize(_svPokemon2!)}',
                _svPassableTo1, Colors.purple.shade50,
              )
            else if (_svEggMoves1.isNotEmpty)
              _buildNoPassableCard(_capitalize(_svPokemon1!), _capitalize(_svPokemon2!)),
            const SizedBox(height: 8),
            if (_svPassableTo2.isNotEmpty)
              _buildPassableMovesCard(
                '${_capitalize(_svPokemon2!)} can inherit from ${_capitalize(_svPokemon1!)}',
                _svPassableTo2, Colors.indigo.shade50,
              )
            else if (_svEggMoves2.isNotEmpty)
              _buildNoPassableCard(_capitalize(_svPokemon2!), _capitalize(_svPokemon1!)),
            // Mirror Herb hint when same species
            if (_svPokemon1 != null &&
                _svPokemon2 != null &&
                _svPokemon1!.toLowerCase() == _svPokemon2!.toLowerCase()) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_florist, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mirror Herb Available',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700)),
                            const SizedBox(height: 4),
                            Text(
                              'Same species detected! Have one hold a Mirror Herb at a Picnic '
                              'with the other to copy egg moves — no breeding needed.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _svChange(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.purple.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.purple.shade800)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade800, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Guide ──────────────────────────────────────────────────────────

  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _guideSection('Compatibility Rules',
              'Two Pokémon can breed if they share at least one Egg Group. '
              'You need one male and one female. The baby is always the same species as the mother '
              '(or the non-Ditto parent).'),
          _guideSection('Ditto',
              'Ditto can breed with any Pokémon except those in the "Undiscovered" egg group. '
              'Ditto is essential for breeding genderless Pokémon (like Magnemite or Staryu). '
              'When breeding with Ditto, the offspring is always the other parent\'s species.'),
          _guideSection('Undiscovered Egg Group',
              'Pokémon in the Undiscovered group (most baby Pokémon and legendaries) '
              'cannot breed at all, not even with Ditto.'),
          _guideSection('Ability Inheritance',
              '• The mother has an 80% chance to pass her ability to offspring.\n'
              '• Hidden Abilities can only be inherited if a parent has the HA.\n'
              '• Females pass HA with a 60% chance.\n'
              '• Males/genderless can only pass HA when breeding with Ditto (60% chance).\n'
              '• Regular abilities: if the mother has ability slot 1, there\'s an 80% chance the baby gets slot 1 and 20% for slot 2.'),
          _guideSection('Nature Inheritance',
              'Give a parent an Everstone to guarantee the baby inherits that parent\'s Nature. '
              'If both parents hold Everstones, it\'s a 50/50 which Nature is passed.'),
          _guideSection('IV Inheritance',
              'Normally, 3 random IVs are inherited from the parents\' combined 12 stats. '
              'If either parent holds a Destiny Knot, 5 IVs are inherited instead. '
              'Power items (Power Bracer, Belt, etc.) guarantee the corresponding stat is one of the inherited IVs.'),
          _guideSection('Egg Moves (Gen 1–8)',
              'Egg moves are special moves a Pokémon can only learn through breeding. '
              'The father passes egg moves to the baby. The father must know the move naturally '
              '(by level-up, TM, or tutor) and share an egg group with the mother.'),
          _guideSection('Egg Moves (Gen 9: Scarlet/Violet)',
              'Either parent can pass egg moves — the gender restriction is removed. '
              'A Pokémon can also copy egg moves from a same-species Pokémon at a Picnic using the Mirror Herb item.'),
          _guideSection('Pokéball Inheritance',
              'The mother\'s Poké Ball is passed to the offspring. When breeding with Ditto, '
              'the non-Ditto parent\'s ball is used. Master Balls and Cherish Balls cannot be inherited.'),
          _guideSection('Egg Steps (Hatching)',
              'Each egg has a hatch counter (egg cycles). Each cycle is 257 steps. '
              'Carrying a Pokémon with Flame Body or Magma Armor halves the steps needed. '
              'In Scarlet/Violet, Egg Power sandwiches can also speed hatching.'),
        ],
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildAutocomplete({required ValueChanged<String> onSelected}) {
    return Autocomplete<String>(
      optionsBuilder: (v) {
        if (v.text.isEmpty) return const Iterable.empty();
        return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
      },
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
        controller: ctrl,
        focusNode: focus,
        decoration: const InputDecoration(
          hintText: 'Search...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    Map<String, dynamic> result,
    String? p1,
    String? p2, {
    bool sv = false,
  }) {
    return Card(
      color: result['compatible'] == true ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              result['compatible'] == true ? Icons.check_circle : Icons.cancel,
              color: result['compatible'] == true ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              result['compatible'] == true ? 'Compatible!' : 'Not Compatible',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: result['compatible'] == true ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(result['reason'] ?? ''),
            if (result['eggGroups1'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${_capitalize(p1 ?? '')}: ${(result['eggGroups1'] as List).map(_formatEggGroup).join(", ")}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '${_capitalize(p2 ?? '')}: ${(result['eggGroups2'] as List).map(_formatEggGroup).join(", ")}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (sv && result['compatible'] == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  'In SV: Set up a Picnic with both in your party to receive eggs.',
                  style: TextStyle(fontSize: 12, color: Colors.purple.shade800),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassableMovesCard(String title, List<Map<String, dynamic>> moves, Color bgColor) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('These egg moves can be passed via breeding with this pair.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: moves
                  .map((m) => Chip(
                        label: Text(m['name'], style: const TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPassableCard(String baby, String parent) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '$parent cannot pass any of $baby\'s egg moves directly.',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _guideSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.5)),
          const Divider(),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  String _formatEggGroup(dynamic g) =>
      (g as String).split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
