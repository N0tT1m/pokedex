import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../../services/breeding_service.dart';

class BreedingChainScreen extends StatefulWidget {
  const BreedingChainScreen({Key? key}) : super(key: key);

  @override
  State<BreedingChainScreen> createState() => _BreedingChainScreenState();
}

class _BreedingChainScreenState extends State<BreedingChainScreen> {
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
    _loadData();
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
      final eggMoves = await BreedingService.getEggMoves(pokemonName);
      setState(() {
        _moveNames = eggMoves.map((m) => m['apiName'] as String).toList();
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
      final moveResponse = await Requests.get('https://pokeapi.co/api/v2/move/${_targetMove!.toLowerCase()}');
      if (moveResponse.statusCode != 200) {
        setState(() { _errorMessage = 'Could not load move data'; _searching = false; });
        return;
      }
      final moveData = moveResponse.json();
      final learnedBy = (moveData['learned_by_pokemon'] as List)
          .map((p) => p['name'] as String).toList();

      // Find direct parents (Pokemon in same egg group that learn the move)
      final directParents = <Map<String, dynamic>>[];

      // Check a sample of Pokemon for egg group compatibility
      for (var pokeName in learnedBy.take(100)) {
        try {
          final species = await PokeApiService.getPokemonSpecies(pokeName);
          final eggGroups = (species['egg_groups'] as List)
              .map((g) => g['name'] as String).toList();

          // Check if this Pokemon shares an egg group with target
          final shared = eggGroups.where((g) => targetEggGroups.contains(g)).toList();
          if (shared.isNotEmpty) {
            // Check how this Pokemon learns the move
            final pokemonData = await PokeApiService.getPokemon(pokeName);
            final moves = pokemonData['moves'] as List;
            String learnMethod = 'unknown';
            for (var move in moves) {
              if (move['move']['name'] == _targetMove) {
                final details = move['version_group_details'] as List;
                for (var d in details) {
                  final method = d['move_learn_method']['name'] as String;
                  if (method == 'level-up' || method == 'machine' || method == 'tutor') {
                    learnMethod = method;
                    break;
                  }
                }
                break;
              }
            }

            if (learnMethod != 'unknown' && learnMethod != 'egg') {
              directParents.add({
                'name': pokeName,
                'learnMethod': learnMethod,
                'sharedGroups': shared,
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

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breeding Chains'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Pokemon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            optionsBuilder: (v) {
                              if (v.text.isEmpty) return const Iterable.empty();
                              return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                            },
                            onSelected: _loadMoves,
                            fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                              controller: ctrl, focusNode: focus,
                              decoration: const InputDecoration(hintText: 'Search Pokemon...', border: OutlineInputBorder()),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: _moveNames.map((m) =>
                                ChoiceChip(
                                  label: Text(_formatName(m)),
                                  selected: _targetMove == m,
                                  onSelected: (v) => setState(() => _targetMove = v ? m : null),
                                )).toList(),
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
                        child: Text('This Pokemon has no egg moves.', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_targetMove != null)
                    ElevatedButton(
                      onPressed: _searching ? null : _findChain,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.all(16)),
                      child: _searching
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
                    const Text('Breeding Parents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('These Pokemon can pass ${_formatName(_targetMove!)} to ${_formatName(_targetPokemon!)} as an egg move.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    ..._chainResults.map((parent) => Card(
                      child: ListTile(
                        title: Text(_formatName(parent['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Learns via ${_formatName(parent['learnMethod'])}\n'
                          'Shared egg group: ${(parent['sharedGroups'] as List).map((g) => _formatName(g as String)).join(", ")}'),
                        isThreeLine: true,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.egg, color: Colors.white),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}
