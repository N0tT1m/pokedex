import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../pokemon/pokemon_detail_sheet.dart';

class BreedingChainScreen extends StatefulWidget {
  const BreedingChainScreen({Key? key}) : super(key: key);

  @override
  State<BreedingChainScreen> createState() => _BreedingChainScreenState();
}

class _BreedingChainScreenState extends State<BreedingChainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _pokemonNames = [];
  List<String> _moveNames = [];
  bool _isLoading = true;
  bool _searching = false;
  String? _targetPokemon;
  String? _targetMove;
  List<Map<String, dynamic>> _chainResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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

  Future<void> _loadMoves(String pokemonName) async {
    try {
      final moves = await PokeApiService.getPokemonMoves(pokemonName.toLowerCase());
      final methodOrder = ['egg', 'level-up', 'tm', 'tutor'];
      final normalized = moves.map((m) {
        final raw = (m['learn_method'] as String? ?? '').toLowerCase();
        final apiName = m['name'] as String? ?? '';
        final displayName = apiName.split('-')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
            .join(' ');
        final method = raw == 'level-up' ? 'level-up'
            : raw == 'tm' ? 'tm'
            : raw == 'egg' ? 'egg'
            : raw == 'tutor' ? 'tutor'
            : null;
        return method != null ? {'apiName': apiName, 'name': displayName, 'method': method} : null;
      }).whereType<Map<String, dynamic>>().toList();

      final seen = <String, Map<String, dynamic>>{};
      for (final m in normalized) {
        final key = m['apiName'] as String;
        if (!seen.containsKey(key) || m['method'] == 'egg') {
          seen[key] = m;
        }
      }
      final sorted = seen.values.toList()
        ..sort((a, b) {
          final ai = methodOrder.indexOf(a['method']);
          final bi = methodOrder.indexOf(b['method']);
          final c = ai.compareTo(bi);
          return c != 0 ? c : (a['name'] as String).compareTo(b['name'] as String);
        });

      final eggOnly = sorted.where((m) => m['method'] == 'egg').toList();

      setState(() {
        _moveNames = eggOnly.map((m) => m['apiName'] as String).toList();
        _targetPokemon = pokemonName;
        _targetMove = null;
        _chainResults = [];
      });
    } catch (_) {}
  }

  Future<void> _findChain() async {
    if (_targetPokemon == null || _targetMove == null) return;
    setState(() { _searching = true; _errorMessage = null; _chainResults = []; });

    try {
      final targetSpecies = await PokeApiService.getPokemonSpecies(_targetPokemon!);
      final targetEggGroups = (targetSpecies['egg_groups'] as List)
          .map((g) => g['name'] as String).toList();

      final moveApiName = _targetMove!.toLowerCase().replaceAll(' ', '-');
      final moveResponse = await Requests.get('${PokeApiService.baseUrl}/move/$moveApiName');
      if (moveResponse.statusCode != 200) {
        setState(() { _errorMessage = 'Could not load move data'; _searching = false; });
        return;
      }
      final moveData = moveResponse.json();
      final learnedBy = (moveData['learned_by_pokemon'] as List)
          .map((p) => p['pokemon']['name'] as String).toList();

      final directParents = <Map<String, dynamic>>[];

      for (var pokeName in learnedBy) {
        try {
          final species = await PokeApiService.getPokemonSpecies(pokeName);
          final eggGroups = (species['egg_groups'] as List)
              .map((g) => g['name'] as String).toList();
          final shared = eggGroups.where((g) => targetEggGroups.contains(g)).toList();
          if (shared.isNotEmpty) {
            final moves = await PokeApiService.getPokemonMoves(pokeName);
            String learnMethod = 'unknown';
            for (var move in moves) {
              if (move['name'] == _targetMove) {
                final method = (move['learn_method'] as String?) ?? '';
                final methodLower = method.toLowerCase();
                if (methodLower.contains('level') || methodLower.contains('tm') ||
                    methodLower.contains('machine') || methodLower.contains('tutor')) {
                  learnMethod = method;
                  break;
                }
              }
            }
            if (learnMethod != 'unknown' && !learnMethod.toLowerCase().contains('egg')) {
              int? pokeId;
              try {
                final pokeData = await PokeApiService.getPokemon(pokeName);
                pokeId = pokeData['id'] as int?;
              } catch (_) {}
              directParents.add({
                'name': pokeName,
                'learnMethod': learnMethod,
                'sharedGroups': shared,
                'id': pokeId,
              });
            }
          }
        } catch (_) {
          continue;
        }
        if (directParents.length >= 10) break;
      }

      setState(() {
        _chainResults = directParents;
        _searching = false;
        if (directParents.isEmpty) {
          _errorMessage = 'No direct breeding parents found. The move may require a multi-step chain.';
        }
      });
    } catch (e) {
      setState(() { _errorMessage = 'Error: $e'; _searching = false; });
    }
  }

  String _fmt(String name) =>
      name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breeding Chains'),
        backgroundColor: Colors.red,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Find Parents'),
            Tab(text: 'Scarlet / Violet'),
            Tab(text: 'How It Works'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFindParentsTab(),
                _buildSVTab(),
                _buildHowItWorksTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 – FIND PARENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFindParentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Target Pokémon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Select the Pokémon you want to give an egg move to.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (v) {
                    if (v.text.isEmpty) return const Iterable.empty();
                    return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                  },
                  onSelected: _loadMoves,
                  fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                    controller: ctrl, focusNode: focus,
                    decoration: const InputDecoration(hintText: 'Search Pokémon...', border: OutlineInputBorder()),
                  ),
                ),
              ]),
            ),
          ),

          if (_targetPokemon != null && _moveNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Egg Moves for ${_fmt(_targetPokemon!)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Select one to find a parent that can pass it down.',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _moveNames.map((m) => ChoiceChip(
                      label: Text(_fmt(m), style: const TextStyle(fontSize: 11)),
                      selected: _targetMove == m,
                      onSelected: (v) => setState(() => _targetMove = v ? m : null),
                    )).toList(),
                  ),
                ]),
              ),
            ),
          ],
          if (_targetPokemon != null && _moveNames.isEmpty && !_isLoading)
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No egg moves found for this Pokémon.', style: TextStyle(color: Colors.grey)),
            )),

          const SizedBox(height: 16),
          if (_targetMove != null)
            ElevatedButton(
              onPressed: _searching ? null : _findChain,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.all(16)),
              child: _searching
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Find Parents for ${_fmt(_targetMove!)}', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          if (_errorMessage != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.orange))),

          if (_chainResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Breeding Parents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('These Pokémon can pass ${_fmt(_targetMove!)} to ${_fmt(_targetPokemon!)} as an egg move.',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            ..._chainResults.map((parent) {
              final parentId = parent['id'] as int?;
              return Card(
                child: ListTile(
                  onTap: () => showPokemonDetailSheet(context, parent['name']),
                  title: Text(
                    parentId != null ? '#$parentId ${_fmt(parent['name'])}' : _fmt(parent['name']),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Learns via ${_fmt(parent['learnMethod'])}\n'
                    'Shared egg group: ${(parent['sharedGroups'] as List).map((g) => _fmt(g as String)).join(", ")}'),
                  isThreeLine: true,
                  leading: parentId != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$parentId.png'),
                          backgroundColor: Colors.pink.shade100)
                      : CircleAvatar(backgroundColor: Colors.pink, child: const Icon(Icons.egg, color: Colors.white)),
                ),
              );
            }),

            // Gen-specific execution tips
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.lightbulb, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Text('How to Execute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900)),
                  ]),
                  const SizedBox(height: 8),
                  _execStep('Gen 2–8', 'The FATHER must know ${_fmt(_targetMove!)}. Breed a male parent from the list above '
                      'with a female ${_fmt(_targetPokemon!)} (or a Ditto). The baby will hatch with the egg move.'),
                  _execStep('Gen 9 (SV)', 'Either parent can pass the move. You can also use a Mirror Herb: '
                      'have ${_fmt(_targetPokemon!)} hold a Mirror Herb, Picnic with a same-species Pokémon that knows '
                      '${_fmt(_targetMove!)} — it copies over without breeding.'),
                  _execStep('Multi-step', 'If no parent above is the right gender or has other moves you need, breed the move '
                      'onto an intermediate Pokémon first (same egg group), then breed that intermediate with ${_fmt(_targetPokemon!)}.'),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _execStep(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(top: 1, right: 8),
          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
        ),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
      ]),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.local_florist, color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text('Mirror Herb — Step-by-Step', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple.shade700)),
                ]),
                const SizedBox(height: 12),
                _svStep(1, 'Buy a Mirror Herb from Delibird Presents (unlocked after 3+ Gym Badges). Costs \u20BD30,000.'),
                _svStep(2, 'You need two Pokémon of the SAME SPECIES. Pokémon A already knows the egg move. Pokémon B is the one you want to teach.'),
                _svStep(3, 'Make sure Pokémon B has an empty move slot. If all 4 slots are full, go to the Move Relearner and forget one.'),
                _svStep(4, 'Give Pokémon B the Mirror Herb item.'),
                _svStep(5, 'Put both in your party and start a Picnic.'),
                _svStep(6, 'End the Picnic after a few seconds. Pokémon B will now know the egg move. The Mirror Herb is consumed.'),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.swap_horiz, color: Colors.deepPurple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text('Egg Move Breeding in SV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple.shade700)),
                ]),
                const SizedBox(height: 12),
                _infoBlock('Either Parent Passes',
                    'In Gen 9, the father OR mother can pass egg moves. The old Gen 2–8 rule that only '
                    'the father can pass them no longer applies.'),
                _infoBlock('How It Works',
                    '1. Parent A must know the egg move AND share an egg group with Parent B.\n'
                    '2. Set up a Picnic with both in your party.\n'
                    '3. The baby that hatches will know the egg move.\n'
                    '4. If both parents know different egg moves, the baby inherits all of them.'),
                _infoBlock('Chains Still Work',
                    'If no Pokémon in the same egg group naturally learns the move, use a chain:\n'
                    '  Step 1: Breed move onto intermediate Pokémon (shares egg group with source).\n'
                    '  Step 2: Breed intermediate with your target (shares egg group).\n\n'
                    'Or: use Mirror Herb on the intermediate, then breed.'),
                _infoBlock('Quick Combo',
                    'For fastest results: find a parent in the "Find Parents" tab, breed once to get the move '
                    'on a same-species Pokémon, then Mirror Herb it onto your competitive specimen.'),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.restaurant, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text('Egg Power Sandwiches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700)),
                ]),
                const SizedBox(height: 10),
                _infoBlock('What It Does',
                    'Egg Power increases the rate at which eggs appear in the Picnic basket. '
                    'At Lv.3, eggs appear every ~10 seconds instead of every ~30.'),
                _infoBlock('Easy Recipes',
                    '• Jam Sandwich (Lv.1): Jam only — basic boost.\n'
                    '• Great PB Sandwich (Lv.2): Banana + Peanut Butter + Butter.\n'
                    '• Herba Mystica combos (Lv.3): Sweet Herba + any fruit — rare but strongest.\n\n'
                    'Herba Mystica drop from 5–6 star Tera Raids.'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _svStep(int n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 10, backgroundColor: Colors.purple.shade200,
          child: Text('$n', style: TextStyle(fontSize: 11, color: Colors.purple.shade900, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 – HOW IT WORKS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHowItWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard('What Are Egg Moves?', Colors.pink, Icons.egg,
              'Egg moves are moves a Pokémon can\'t learn by leveling up or TM, but CAN inherit from a parent during breeding.\n\n'
              'Example: Charmander can learn Dragon Dance as an egg move, but never by level-up. '
              'You breed a male Axew (learns Dragon Dance by level-up, shares Monster egg group with Charmander) '
              'with a female Charmander — the baby Charmander knows Dragon Dance.'),

          _infoCard('How Egg Moves Pass (Gen 2–8)', Colors.blue, Icons.male,
              '1. The FATHER must know the egg move.\n'
              '2. He must share at least one Egg Group with the mother.\n'
              '3. The baby is the mother\'s species.\n'
              '4. The baby hatches knowing the egg move.\n\n'
              'The father can know the move by level-up, TM, or move tutor. '
              'He CANNOT pass a move he only knows as an egg move himself — '
              'that\'s where chains come in.'),

          _infoCard('How Egg Moves Pass (Gen 9)', Colors.purple, Icons.swap_horiz,
              'Either parent can pass egg moves — gender doesn\'t matter.\n'
              'Mirror Herb: same-species transfer without breeding at all.'),

          _infoCard('What Is a Breeding Chain?', Colors.orange, Icons.link,
              'When no Pokémon in the same egg group as your target learns the move directly.\n\n'
              'Solution: breed the move onto an INTERMEDIATE Pokémon first, then breed that intermediate with your target.\n\n'
              'Chain example:\n'
              '  Smeargle (Sketch → any move) → breed with Pokémon B (Field group)\n'
              '  Pokémon B now has the move as an egg move → breed with Pokémon C (shares egg group with B)\n'
              '  Pokémon C now has the move.\n\n'
              'Chains can be 2, 3, or even 4 steps long.'),

          _infoCard('Chain Tips', Colors.teal, Icons.tips_and_updates,
              '• Smeargle (Field egg group) can Sketch any move in battle. In Gen 2–8, this makes it a universal egg move source for any Pokémon in the Field group.\n'
              '• Check both parents\' egg groups — sometimes there\'s a Pokémon that bridges two groups.\n'
              '• In Gen 8+, same-species transfer at the Nursery/Picnic means you only need ONE Pokémon with the move to spread it to others of the same species.\n'
              '• TM compatibility changes per generation — a parent that can\'t learn a move in Gen 5 might learn it in Gen 8 via a new TM.'),

          _infoCard('Generation Differences Summary', Colors.grey, Icons.history,
              '• Gen 2–5: Father passes egg moves. 3 IVs inherited. No Destiny Knot for IVs.\n'
              '• Gen 6–7: Father passes egg moves. Destiny Knot → 5 IVs. Males pass HA with Ditto.\n'
              '• Gen 8: Same as Gen 6–7 + same-species transfer at Nursery (one empty slot needed).\n'
              '• Gen 9: Either parent. Mirror Herb same-species copy. Picnic breeding.'),
        ],
      ),
    );
  }

  Widget _infoCard(String title, Color color, IconData icon, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color))),
          ]),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.5)),
        ]),
      ),
    );
  }

  Widget _infoBlock(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4)),
      ]),
    );
  }
}
