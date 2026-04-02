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
    _tabController = TabController(length: 2, vsync: this);
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
      // Normalize DB lowercase values and skip unknown methods
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

      // Deduplicate by apiName, prefer egg method if multiple
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
      // Get target Pokemon's egg groups
      final targetSpecies = await PokeApiService.getPokemonSpecies(_targetPokemon!);
      final targetEggGroups = (targetSpecies['egg_groups'] as List)
          .map((g) => g['name'] as String).toList();

      // Get all Pokemon that learn this move by level-up or TM (potential parents)
      final moveApiName = _targetMove!.toLowerCase().replaceAll(' ', '-');
      final moveResponse = await Requests.get('${PokeApiService.baseUrl}/move/$moveApiName');
      if (moveResponse.statusCode != 200) {
        setState(() { _errorMessage = 'Could not load move data'; _searching = false; });
        return;
      }
      final moveData = moveResponse.json();
      final learnedBy = (moveData['learned_by_pokemon'] as List)
          .map((p) => p['pokemon']['name'] as String).toList();

      // Find direct parents (Pokemon in same egg group that learn the move)
      final directParents = <Map<String, dynamic>>[];

      // Check a sample of Pokemon for egg group compatibility
      for (var pokeName in learnedBy) {
        try {
          final species = await PokeApiService.getPokemonSpecies(pokeName);
          final eggGroups = (species['egg_groups'] as List)
              .map((g) => g['name'] as String).toList();

          // Check if this Pokemon shares an egg group with target
          final shared = eggGroups.where((g) => targetEggGroups.contains(g)).toList();
          if (shared.isNotEmpty) {
            // Check how this Pokemon learns the move
            final moves = await PokeApiService.getPokemonMoves(pokeName);
            String learnMethod = 'unknown';
            for (var move in moves) {
              if (move['name'] == _targetMove) {
                final method = (move['learn_method'] as String?) ?? '';
                final methodLower = method.toLowerCase();
                if (methodLower.contains('level') || methodLower.contains('tm') || methodLower.contains('machine') || methodLower.contains('tutor')) {
                  learnMethod = method;
                  break;
                }
              }
            }

            if (learnMethod != 'unknown' && !learnMethod.toLowerCase().contains('egg')) {
              // Get the Pokemon ID for display
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

        // Limit results
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

  Widget _infoBlock(String title, String body) {
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

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

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
            Tab(text: 'Scarlet/Violet'),
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
              ],
            ),
    );
  }

  Widget _buildFindParentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.pink.shade50,
            child: Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(Icons.egg_outlined, color: Colors.pink.shade700),
                title: Text('How Egg Moves Work',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.pink.shade700)),
                subtitle: Text('Tap to learn about egg move inheritance',
                    style: TextStyle(fontSize: 12, color: Colors.pink.shade400)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoBlock('What are Egg Moves?',
                            'Egg moves are moves that a Pokémon can\'t learn by leveling up or TM, '
                            'but can inherit from a parent during breeding. For example, Charmander '
                            'can learn Dragon Dance as an egg move, but never by level-up.'),
                        _infoBlock('How to Pass Egg Moves (Gen 1–8)',
                            '1. Find a Pokémon that learns the move naturally (level-up, TM, or tutor).\n'
                            '2. That Pokémon must share an Egg Group with your target Pokémon.\n'
                            '3. Breed them together — the baby will know the egg move.\n\n'
                            'In Gen 8 and earlier, only the father can pass egg moves.'),
                        _infoBlock('Egg Moves in Gen 9 (Scarlet/Violet)',
                            'In Scarlet/Violet, EITHER parent can pass egg moves — the gender restriction '
                            'is removed. See the Scarlet/Violet tab for Mirror Herb transfers.'),
                        _infoBlock('Breeding Chains',
                            'Sometimes no Pokémon in the same egg group learns the move directly. '
                            'In that case, you need a chain: breed the move onto an intermediate Pokémon '
                            'first (as an egg move), then breed that intermediate with your target.\n\n'
                            'Example: Pokémon A learns Move X by level-up → breed with Pokémon B '
                            '(same egg group) → B now has Move X as egg move → breed B with '
                            'Pokémon C (B and C share an egg group) → C now has Move X.'),
                        _infoBlock('How to Use This Tool',
                            'Select your target Pokémon below, pick an egg move, and this tool '
                            'will find parents that can pass it down. It shows which egg group they '
                            'share and how the parent learns the move (level-up, TM, or tutor).'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Pokémon',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return const Iterable.empty();
                      return _pokemonNames
                          .where((n) => n.contains(v.text.toLowerCase()))
                          .take(10);
                    },
                    onSelected: _loadMoves,
                    fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                      controller: ctrl,
                      focusNode: focus,
                      decoration: const InputDecoration(
                          hintText: 'Search Pokémon...', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_targetPokemon != null && _moveNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Egg Moves for ${_formatName(_targetPokemon!)}',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                        'Select one to find a parent that can pass it down.',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _moveNames.map((m) {
                        return ChoiceChip(
                          label: Text(_formatName(m),
                              style: const TextStyle(fontSize: 11)),
                          selected: _targetMove == m,
                          onSelected: (v) =>
                              setState(() => _targetMove = v ? m : null),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_targetPokemon != null && _moveNames.isEmpty && !_isLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No egg moves found for this Pokémon.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 16),
          if (_targetMove != null)
            ElevatedButton(
              onPressed: _searching ? null : _findChain,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, padding: const EdgeInsets.all(16)),
              child: _searching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Find Parents for ${_formatName(_targetMove!)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.orange)),
            ),
          if (_chainResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Breeding Parents',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'These Pokémon can pass ${_formatName(_targetMove!)} to ${_formatName(_targetPokemon!)} as an egg move.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ..._chainResults.map((parent) {
              final parentId = parent['id'] as int?;
              return Card(
                child: ListTile(
                  onTap: () => showPokemonDetailSheet(context, parent['name']),
                  title: Text(
                      parentId != null
                          ? '#$parentId ${_formatName(parent['name'])}'
                          : _formatName(parent['name']),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Learns via ${_formatName(parent['learnMethod'])}\n'
                      'Shared egg group: ${(parent['sharedGroups'] as List).map((g) => _formatName(g as String)).join(", ")}'),
                  isThreeLine: true,
                  leading: parentId != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$parentId.png'),
                          backgroundColor: Colors.pink.shade100,
                        )
                      : const CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.egg, color: Colors.white),
                        ),
                ),
              );
            }),
            // SV Mirror Herb shortcut note
            if (_targetPokemon != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_florist, color: Colors.purple.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scarlet/Violet shortcut',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700)),
                            const SizedBox(height: 4),
                            Text(
                              'In SV you can skip breeding: have ${_formatName(_targetPokemon!)} hold a Mirror Herb '
                              'at a Picnic with a same-species Pokémon that already knows '
                              '${_targetMove != null ? _formatName(_targetMove!) : "the egg move"}. '
                              'The Mirror Herb Pokémon copies the move instantly — works on males and genderless too.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade800, height: 1.4),
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
                  Row(
                    children: [
                      Icon(Icons.egg_alt, color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text('Egg Moves in Scarlet/Violet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.purple.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoBlock('Either Parent Passes Egg Moves',
                      'Unlike Gen 1–8 where only the father could pass egg moves, '
                      'in Scarlet/Violet EITHER parent can pass them. Simply breed two compatible '
                      'Pokémon at a Picnic and either one knowing the egg move will pass it.'),
                  _infoBlock('Mirror Herb — Skip Breeding Entirely',
                      'Buy a Mirror Herb from Delibird Presents (after unlocking 3+ gyms). '
                      'Give it to a Pokémon, then place it in a Picnic alongside a same-species '
                      'Pokémon that knows the egg move. The Mirror Herb Pokémon will copy every '
                      'egg move the other Pokémon knows that it could normally learn via egg.\n\n'
                      'This works on ANY gender (including male and genderless). '
                      'The Mirror Herb is consumed after use.'),
                  _infoBlock('Step-by-Step: Mirror Herb Transfer',
                      '1. Have Pokémon A (knows the egg move) and Pokémon B (doesn\'t) of the same species.\n'
                      '2. Give Pokémon B the Mirror Herb item.\n'
                      '3. Set up a Picnic with both in your party.\n'
                      '4. After a moment, check Pokémon B\'s moves — it will have copied the egg move.\n'
                      '5. The Mirror Herb is used up; obtain another from Delibird Presents if needed.'),
                  _infoBlock('Egg Power Sandwiches',
                      'Eating an Egg Power sandwich at a Picnic increases the rate at which eggs appear '
                      'and can influence egg hatching for Pokémon of a specific type:\n\n'
                      '• Egg Power Lv.1 — More eggs appear.\n'
                      '• Egg Power Lv.2 — More eggs + higher chance of same-type Pokémon in eggs.\n'
                      '• Egg Power Lv.3 — Maximum egg rate + guaranteed Pokémon type in eggs.\n\n'
                      'Recipes change by game version and unlocked sandwiches.'),
                  _infoBlock('Breeding Chains in SV',
                      'The chain mechanic still applies in SV: if no direct parent exists '
                      'in the egg group, you breed through an intermediate Pokémon. '
                      'However, you can also use Mirror Herb to jump steps if a same-species '
                      'Pokémon already has the egg move from a previous chain.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
