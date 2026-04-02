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
  bool _isLoading = true;

  // Compatibility tab
  String? _pokemon1;
  String? _pokemon2;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _eggMoves1 = [];
  List<Map<String, dynamic>> _eggMoves2 = [];
  List<Map<String, dynamic>> _passableTo1 = [];
  List<Map<String, dynamic>> _passableTo2 = [];
  bool _isChecking = false;

  // SV tab
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
    _tabController = TabController(length: 4, vsync: this);
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
      final err = {'compatible': false, 'reason': 'Error: $e'};
      setState(() {
        if (sv) { _svResult = err; _svChecking = false; }
        else { _result = err; _isChecking = false; }
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Compatibility'),
            Tab(text: 'Scarlet / Violet'),
            Tab(text: 'By Generation'),
            Tab(text: 'Strategies'),
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
                _buildByGenerationTab(),
                _buildStrategiesTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 – COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCompatibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPairChecker(
            p1: _pokemon1,
            p2: _pokemon2,
            onP1: (v) => setState(() => _pokemon1 = v),
            onP2: (v) => setState(() => _pokemon2 = v),
            checking: _isChecking,
            onCheck: () => _checkCompatibility(),
            label: 'Standard Compatibility Check',
            sublabel: 'Applies to Gen 2 – 9. Select two Pokémon to see if they can breed.',
            buttonColor: Colors.blue,
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_result!, _pokemon1, _pokemon2),
            _buildSpeciesInfoCards(_result!, _pokemon1!, _pokemon2!),
            _buildBreedingStrategyCard(_result!, _pokemon1!, _pokemon2!),
          ],
          if (_result != null && (_eggMoves1.isNotEmpty || _eggMoves2.isNotEmpty)) ...[
            const SizedBox(height: 12),
            if (_eggMoves1.isNotEmpty)
              _buildFullEggMovesCard(
                _cap(_pokemon1!), _cap(_pokemon2!),
                _eggMoves1, _passableTo1, Colors.green),
            if (_eggMoves2.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildFullEggMovesCard(
                _cap(_pokemon2!), _cap(_pokemon1!),
                _eggMoves2, _passableTo2, Colors.blue),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSpeciesInfoCards(Map<String, dynamic> result, String p1, String p2) {
    final s1 = result['species1'] as Map<String, dynamic>?;
    final s2 = result['species2'] as Map<String, dynamic>?;
    if (s1 == null || s2 == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Species Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _speciesRow(_cap(p1), s1),
              const Divider(height: 16),
              _speciesRow(_cap(p2), s2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _speciesRow(String name, Map<String, dynamic> info) {
    final eggCycles = info['eggCycles'] ?? 0;
    final baseSteps = info['baseSteps'] ?? 0;
    final halfSteps = info['halfSteps'] ?? 0;
    final genderText = info['genderText'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        _detailLine(Icons.female, 'Gender', genderText),
        _detailLine(Icons.egg, 'Egg Cycles', '$eggCycles cycles ($baseSteps steps)'),
        _detailLine(Icons.directions_walk, 'With Flame Body',
            '$halfSteps steps (halved)'),
      ],
    );
  }

  Widget _detailLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBreedingStrategyCard(Map<String, dynamic> result, String p1, String p2) {
    if (result['compatible'] != true) return const SizedBox.shrink();

    final s1 = result['species1'] as Map<String, dynamic>?;
    final s2 = result['species2'] as Map<String, dynamic>?;
    final g1 = s1?['genderText'] as String? ?? '';
    final g2 = s2?['genderText'] as String? ?? '';
    final isDitto = (result['eggGroups1'] as List?)?.contains('ditto') == true ||
        (result['eggGroups2'] as List?)?.contains('ditto') == true;

    final steps = <String>[];

    if (isDitto) {
      final nonDitto = (result['eggGroups1'] as List?)?.contains('ditto') == true ? p2 : p1;
      steps.addAll([
        'Give ${_cap(nonDitto)} an Everstone to pass its Nature to the offspring.',
        'Give Ditto a Destiny Knot to pass 5 of its 12 combined IVs.',
        'If you want the Hidden Ability, ${_cap(nonDitto)} must already have it (60% pass rate).',
        'Hatch eggs until the offspring has the desired IV spread.',
        'Swap in better parents as you breed — each generation improves IVs.',
      ]);
    } else {
      // Determine mother/father
      String mother = p2;
      String father = p1;
      if (g1.contains('Female') && !g2.contains('Female')) {
        mother = p1;
        father = p2;
      }
      steps.addAll([
        'Mother = ${_cap(mother)} (offspring species), Father = ${_cap(father)}.',
        'Give the parent with the desired Nature an Everstone.',
        'Give the other parent a Destiny Knot to pass 5 IVs.',
        'Egg moves: the FATHER must know the move in Gen 2–8. In Gen 9, either parent works.',
        'Hidden Ability: only the mother passes HA to offspring (60% chance). With Ditto the non-Ditto parent passes it.',
        'Pokéball: offspring inherits the mother\'s ball (or non-Ditto parent\'s).',
        'Hatch and repeat — each batch gets closer to a perfect spread.',
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.lightbulb, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Text('Breeding Strategy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber.shade900)),
              ]),
              const SizedBox(height: 8),
              ...steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${e.key + 1}.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900)),
                        ),
                        Expanded(child: Text(e.value,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 – SCARLET / VIOLET
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSVTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.new_releases, color: Colors.purple.shade700, size: 20),
                    const SizedBox(width: 6),
                    Text('What Changed in Scarlet/Violet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple.shade700)),
                  ]),
                  const SizedBox(height: 12),
                  _svItem(Icons.lunch_dining, 'Picnic Breeding',
                      'Breeding happens at Picnics instead of a Day Care. Put two compatible '
                      'Pokémon in your party, start a Picnic, and eggs appear in the basket.'),
                  _svItem(Icons.swap_horiz, 'Either Parent Passes Egg Moves',
                      'Both the father AND mother can pass egg moves. No more hunting for the right-gender parent.'),
                  _svItem(Icons.restaurant, 'Egg Power Sandwiches',
                      'Eat a sandwich with Egg Power to increase egg frequency:\n'
                      '  Lv.1 → more eggs  |  Lv.2 → many more eggs  |  Lv.3 → maximum egg rate.\n'
                      'Recipes: Great Peanut Butter Sandwich (Lv.2), Jam Sandwich + Herba Mystica (Lv.3).'),
                  _svItem(Icons.local_florist, 'Mirror Herb (No Breeding Needed)',
                      'Buy a Mirror Herb from Delibird Presents. Give it to a Pokémon, then '
                      'Picnic it with a same-species Pokémon that knows the egg move. '
                      'The Mirror Herb copies the move. Works on any gender. Herb is consumed.'),
                  _svItem(Icons.directions_walk, 'Hatching Tips',
                      '• Flame Body / Magma Armor in party still halves steps.\n'
                      '• Egg Power from a sandwich stacks with Flame Body.\n'
                      '• Ride Koraidon/Miraidon in circles to rack up steps quickly.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step-by-step SV competitive breeding
          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.format_list_numbered, color: Colors.deepPurple.shade700, size: 20),
                    const SizedBox(width: 6),
                    Text('SV Competitive Breeding Walkthrough',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepPurple.shade700)),
                  ]),
                  const SizedBox(height: 10),
                  _stepRow(1, 'Get a 6 IV Ditto from 6-star Tera Raid Dens. Give it a Destiny Knot.'),
                  _stepRow(2, 'Catch a parent of the species you want. If you need a Hidden Ability, use an Ability Patch (from 6-star Raids) or catch one with the HA in the wild.'),
                  _stepRow(3, 'Give the non-Ditto parent an Everstone to lock in the Nature you want. If you don\'t have the right Nature yet, use a Mint first to confirm what you need, then breed one with the right Nature.'),
                  _stepRow(4, 'Picnic → eat an Egg Power Lv.2+ sandwich → collect eggs from the basket. ~30 s per egg.'),
                  _stepRow(5, 'Hatch eggs (Flame Body party lead). Swap in higher-IV offspring as the new parent each batch.'),
                  _stepRow(6, 'For egg moves: breed with a parent who knows the move, OR use Mirror Herb on a same-species Pokémon that already has it.'),
                  _stepRow(7, 'Once done, use Bottle Caps or Hyper Training at Lv.50+ to fix the last imperfect IV.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SV Compatibility Checker
          _buildPairChecker(
            p1: _svPokemon1,
            p2: _svPokemon2,
            onP1: (v) => setState(() => _svPokemon1 = v),
            onP2: (v) => setState(() => _svPokemon2 = v),
            checking: _svChecking,
            onCheck: () => _checkCompatibility(sv: true),
            label: 'SV Picnic Compatibility',
            sublabel: 'Egg group rules are the same as older gens.',
            buttonColor: Colors.purple,
          ),
          if (_svResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(_svResult!, _svPokemon1, _svPokemon2, sv: true),
          ],
          if (_svResult != null && (_svEggMoves1.isNotEmpty || _svEggMoves2.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text('In SV, either parent can pass egg moves — not just the father.',
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade800)),
              ),
            ),
            const SizedBox(height: 8),
            if (_svEggMoves1.isNotEmpty)
              _buildFullEggMovesCard(
                _cap(_svPokemon1!), _cap(_svPokemon2!),
                _svEggMoves1, _svPassableTo1, Colors.purple),
            if (_svEggMoves2.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildFullEggMovesCard(
                _cap(_svPokemon2!), _cap(_svPokemon1!),
                _svEggMoves2, _svPassableTo2, Colors.indigo),
            ],
            // Mirror Herb hint for same species
            if (_svPokemon1 != null &&
                _svPokemon2 != null &&
                _svPokemon1!.toLowerCase() == _svPokemon2!.toLowerCase()) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.local_florist, color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Same species — use a Mirror Herb at a Picnic to copy egg moves without breeding.',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                    )),
                  ]),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _svItem(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.purple.shade600),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple.shade800)),
          const SizedBox(height: 2),
          Text(body, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _stepRow(int n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.deepPurple.shade200,
          child: Text('$n', style: TextStyle(fontSize: 11, color: Colors.deepPurple.shade900, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 – BY GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildByGenerationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('How Breeding Differs Across Generations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4),
          Text('Each generation changed or added breeding mechanics. '
              'Tap a generation to see what\'s unique.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),

          _genCard('Gen 2 (Gold / Silver / Crystal)', Colors.amber, [
            'Breeding introduced! Pokémon breed at the Day Care on Route 34.',
            'Egg moves: father passes moves to the baby.',
            'IVs (then called DVs): offspring inherits Defense DV from father, Special from the parent of opposite gender, and others are random.',
            'No items influence breeding — no Everstone or Destiny Knot for breeding yet.',
            'Shiny breeding: since shininess was DV-based, breeding with a shiny parent increased shiny odds.',
            'Gender is determined by the Attack DV — high Attack DV = male, which means female Pokémon have low Attack.',
          ]),

          _genCard('Gen 3 (Ruby / Sapphire / Emerald / FRLG)', Colors.red.shade300, [
            'IVs overhauled to the modern 0–31 system. 3 random IVs are inherited from parents.',
            'Everstone: the mother can hold an Everstone for a 50% chance to pass her Nature.',
            'Egg moves: still father-only.',
            'Abilities introduced — offspring gets one of the species\' regular abilities at random.',
            'No Destiny Knot for breeding.',
            'Pokéball: offspring is always in a standard Poké Ball.',
          ]),

          _genCard('Gen 4 (Diamond / Pearl / Platinum / HGSS)', Colors.blue.shade300, [
            'Everstone nature passing now works for EITHER parent (not just mother).',
            'Power items (Power Bracer, Belt, etc.): guarantee 1 specific IV is inherited.',
            'Still 3 inherited IVs total (one can be forced by a Power item).',
            'Egg moves: still father-only.',
            'Incense breeding added: hold a specific incense to breed baby Pokémon (e.g., Sea Incense → Azurill).',
            'The Masuda Method was introduced — breeding two Pokémon from different real-world language games increases shiny odds to ~1/1638.',
          ]),

          _genCard('Gen 5 (Black / White / B2W2)', Colors.grey.shade400, [
            'Hidden Abilities introduced. Females with HA have a 60% chance to pass it; males/genderless cannot pass HA.',
            'Pokéball inheritance: the mother\'s ball is now passed to offspring.',
            'Everstone nature passing guaranteed (100%, up from 50%).',
            'Still 3 IVs inherited; Power items still force one.',
            'Egg moves: still father-only.',
            'Masuda Method: shiny odds improved to ~1/1365.',
          ]),

          _genCard('Gen 6 (X / Y / ORAS)', Colors.blue.shade700, [
            'Destiny Knot: when held by EITHER parent, 5 IVs are inherited instead of 3. This is the single biggest breeding change — makes competitive IV breeding practical.',
            'Males and genderless Pokémon can now pass Hidden Abilities when breeding with Ditto.',
            'Pokéball: both parents\' balls have a 50/50 chance of being inherited (same-species breeding). Breeding with Ditto always uses the non-Ditto parent\'s ball.',
            'Egg moves: still father-only, but breeding chains became easier with wider TM compatibility.',
            'Friend Safari: a popular source for Pokémon with 2 guaranteed perfect IVs.',
            'Masuda + Shiny Charm: odds drop to ~1/512.',
          ]),

          _genCard('Gen 7 (Sun / Moon / USUM)', Colors.orange, [
            'Identical to Gen 6 mechanically.',
            'Nursery replaces Day Care in Alola — Pokémon no longer gain EXP while stored.',
            'Hyper Training introduced — at Lv.100, use a Bottle Cap to make a stat "Best" without actually changing the IV. Eliminates need for a full 6 IV breed.',
            'SOS chaining for Hidden Abilities made wild HA easier to find.',
            'Masuda + Shiny Charm: still ~1/512.',
          ]),

          _genCard('Gen 8 (Sword / Shield / BDSP)', Colors.cyan, [
            'Same core mechanics as Gen 6/7.',
            'Max Raid Dens: 5-star Ditto raids guarantee 4+ perfect IVs — easiest 6 IV Ditto ever.',
            'Ability Patch: changes a Pokémon\'s ability to its Hidden Ability. Eliminates the need to breed for HA from scratch.',
            'Nature Mints: change the stat modifiers of a Nature without changing the actual Nature value. The mint-modified Nature is NOT passed via Everstone.',
            'Egg moves can be transferred between Pokémon of the same species: leave both at the Nursery (one empty move slot needed).',
            'Pokéball Plus and Home compatibility for transferring bred Pokémon.',
          ]),

          _genCard('Gen 9 (Scarlet / Violet)', Colors.purple, [
            'See the "Scarlet/Violet" tab for full details.',
            'Key differences: Picnic breeding, either parent passes egg moves, Mirror Herb for egg move transfer, Egg Power sandwiches.',
            'Ability Patch available from 6-star Tera Raids.',
            'Bottle Caps available at Delibird Presents after 6 Gyms.',
          ]),
        ],
      ),
    );
  }

  Widget _genCard(String title, Color color, List<String> points) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(p, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4 – STRATEGIES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStrategiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _strategyCard(
            'Perfect IV Breeding (Gen 6+)',
            Colors.blue,
            Icons.star,
            [
              'Start with a 5–6 IV Ditto. In XY use Friend Safari; in SwSh use 5-star Raid Dens; in SV use 6-star Tera Raids.',
              'Give Ditto a Destiny Knot → 5 of 12 combined IVs passed to baby.',
              'Give the other parent an Everstone → Nature is guaranteed.',
              'Hatch a batch. Check IVs (Judge function unlocked post-game).',
              'Swap in the best offspring as the new parent each generation.',
              'Typically takes 3–5 generations to reach a 5 IV spread.',
              'Use a Bottle Cap / Hyper Training at Lv.50+ (Gen 7+) to fix the last imperfect stat.',
            ],
          ),

          _strategyCard(
            'Hidden Ability Breeding',
            Colors.purple,
            Icons.visibility,
            [
              'You MUST start with a parent that has the Hidden Ability already.',
              'Sources: SOS chains (Gen 7), Max Raids (Gen 8), Tera Raids (Gen 9), Ability Patch (Gen 8+).',
              'Female with HA: 60% chance to pass HA to offspring.',
              'Male/genderless with HA: can only pass HA when breeding with Ditto (60%).',
              'If the HA doesn\'t pass, the offspring gets a regular ability. Keep hatching.',
              'Gen 8+: An Ability Patch (from hard raids) changes any Pokémon to its HA, bypassing breeding entirely.',
            ],
          ),

          _strategyCard(
            'Egg Move Chains',
            Colors.pink,
            Icons.egg,
            [
              'Check the "Breeding Chains" tool for specific chains.',
              'Gen 2–8: only the FATHER passes egg moves. The father must know the move AND share an egg group with the mother.',
              'Gen 9: either parent passes egg moves.',
              'Multi-step chain: if no direct parent shares the egg group, breed the move onto an intermediate Pokémon first.',
              'Example: A (level-up move X) → breed with B (same egg group) → B learns X as egg move → breed B with C (B & C share egg group) → C has move X.',
              'Gen 8+: same-species transfer — leave two of the same species at Nursery/Picnic, one knows the egg move, the other has an empty move slot.',
              'Gen 9: Mirror Herb — fastest method. Same species, Picnic, no breeding needed.',
            ],
          ),

          _strategyCard(
            'Shiny Breeding (Masuda Method)',
            Colors.amber,
            Icons.auto_awesome,
            [
              'Breed two Pokémon from different real-world language games (e.g., English + Japanese).',
              'Gen 4: ~1/1638 odds (vs 1/8192 normally).',
              'Gen 5: ~1/1365 odds.',
              'Gen 6+: ~1/683 odds (vs 1/4096 normally). With Shiny Charm: ~1/512.',
              'Shiny Charm: obtained by completing the National/Regional Pokédex (game-dependent).',
              'Strategy: get a foreign Ditto (trade online), breed normally with Destiny Knot + Everstone, and just hatch many eggs.',
              'Average: ~500 eggs with Masuda + Shiny Charm. Can be fewer or many more — it\'s luck.',
            ],
          ),

          _strategyCard(
            'Nature & EV Optimisation',
            Colors.green,
            Icons.tune,
            [
              'Everstone: guarantees the holder\'s Nature is passed. Works since Gen 4.',
              'If both parents hold Everstones, 50/50 which Nature is used.',
              'Gen 8+ Mints: change stat modifiers without changing the actual Nature. Warning: Everstone passes the original Nature, NOT the mint-modified one.',
              'Recommendation: breed for the correct Nature rather than relying on mints if you plan further breeding.',
              'Power items (Bracer, Belt, Lens, Band, Anklet, Weight): force that stat\'s IV to be inherited. Useful before Gen 6 (before Destiny Knot was available for breeding).',
            ],
          ),

          _strategyCard(
            'Quick Reference: Items',
            Colors.teal,
            Icons.backpack,
            [
              'Destiny Knot → 5 IVs inherited (was 3). Available Gen 6+.',
              'Everstone → Nature guaranteed. Reliable since Gen 4.',
              'Power Bracer → Attack IV inherited. (Similarly: Belt=Def, Lens=SpA, Band=SpD, Anklet=Spe, Weight=HP.)',
              'Ability Patch → Switches to Hidden Ability. Gen 8+ raids.',
              'Ability Capsule → Switches between regular abilities 1 ↔ 2. Gen 6+.',
              'Mirror Herb → Copy egg moves same-species, no breeding. Gen 9 only.',
              'Oval Charm → Increases egg rate. Post-game reward in most games.',
              'Shiny Charm → +2 shiny rolls. Complete the Pokédex.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _strategyCard(String title, Color color, IconData icon, List<String> steps) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Icon(icon, color: color, size: 22),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 22, child: Text('${e.key + 1}.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color))),
                    Expanded(child: Text(e.value, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPairChecker({
    required String? p1,
    required String? p2,
    required ValueChanged<String> onP1,
    required ValueChanged<String> onP2,
    required bool checking,
    required VoidCallback onCheck,
    required String label,
    required String sublabel,
    required Color buttonColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(sublabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          const Text('Parent 1'),
          const SizedBox(height: 4),
          _autoField(onP1),
          const SizedBox(height: 12),
          const Text('Parent 2'),
          const SizedBox(height: 4),
          _autoField(onP2),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: checking ? null : onCheck,
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
              child: checking
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Check Compatibility', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _autoField(ValueChanged<String> onSelected) {
    return Autocomplete<String>(
      optionsBuilder: (v) {
        if (v.text.isEmpty) return const Iterable.empty();
        return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
      },
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
        controller: ctrl, focusNode: focus,
        decoration: const InputDecoration(hintText: 'Search...', border: OutlineInputBorder()),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, String? p1, String? p2, {bool sv = false}) {
    final ok = result['compatible'] == true;
    return Card(
      color: ok ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(ok ? 'Compatible!' : 'Not Compatible',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: ok ? Colors.green : Colors.red)),
          const SizedBox(height: 8),
          Text(result['reason'] ?? '', textAlign: TextAlign.center),
          if (result['eggGroups1'] != null) ...[
            const SizedBox(height: 8),
            Text('${_cap(p1 ?? '')}: ${(result['eggGroups1'] as List).map(_fmtEg).join(", ")}', style: const TextStyle(fontSize: 12)),
            Text('${_cap(p2 ?? '')}: ${(result['eggGroups2'] as List).map(_fmtEg).join(", ")}', style: const TextStyle(fontSize: 12)),
          ],
          if (sv && ok) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purple.shade200)),
              child: Text('Set up a Picnic with both in your party to receive eggs.', style: TextStyle(fontSize: 12, color: Colors.purple.shade800), textAlign: TextAlign.center),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildFullEggMovesCard(
    String baby, String partner,
    List<Map<String, dynamic>> allEggMoves,
    List<Map<String, dynamic>> passableMoves,
    Color color,
  ) {
    final passableNames = passableMoves.map((m) => m['apiName'] as String).toSet();
    final canPass = allEggMoves.where((m) => passableNames.contains(m['apiName'])).toList();
    final cantPass = allEggMoves.where((m) => !passableNames.contains(m['apiName'])).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$baby\'s Egg Moves (${allEggMoves.length})',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          const SizedBox(height: 4),
          Text('All moves $baby can learn through breeding.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          if (canPass.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text('$partner can pass directly (${canPass.length})',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ]),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: canPass.map((m) => Chip(
                label: Text(m['name'], style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.green.shade50,
                side: BorderSide(color: Colors.green.shade200),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
          if (cantPass.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.link, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text('Needs a different parent or chain (${cantPass.length})',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
            ]),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: cantPass.map((m) => Chip(
                label: Text(m['name'], style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const SizedBox(height: 6),
            Text('Use the Breeding Chains tool to find parents for these moves.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
          if (canPass.isEmpty) ...[
            const SizedBox(height: 8),
            Text('$partner can\'t pass any of these directly — use the Breeding Chains tool to find a parent.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ]),
      ),
    );
  }

  String _cap(String s) => s.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  String _fmtEg(dynamic g) => (g as String).split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
