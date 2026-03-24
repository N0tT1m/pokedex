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

  String _capitalize(String s) => s.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  String _formatEggGroup(dynamic g) => (g as String).split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
