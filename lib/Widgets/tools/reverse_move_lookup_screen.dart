import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

class ReverseMoveLookupScreen extends StatefulWidget {
  const ReverseMoveLookupScreen({Key? key}) : super(key: key);

  @override
  State<ReverseMoveLookupScreen> createState() => _ReverseMoveLookupScreenState();
}

class _ReverseMoveLookupScreenState extends State<ReverseMoveLookupScreen> {
  List<String> _moveNames = [];
  bool _isLoading = true;
  bool _loadingResults = false;
  String? _selectedMove;
  Map<String, dynamic>? _moveData;
  List<Map<String, dynamic>> _pokemonList = [];
  String _filterMethod = 'all';

  @override
  void initState() {
    super.initState();
    _loadMoveList();
  }

  Future<void> _loadMoveList() async {
    try {
      final response = await Requests.get('https://pokeapi.co/api/v2/move?limit=1000');
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _moveNames = (data['results'] as List).map((m) => m['name'] as String).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoveDetails(String moveName) async {
    setState(() { _loadingResults = true; _selectedMove = moveName; });
    try {
      final response = await Requests.get('https://pokeapi.co/api/v2/move/${moveName.toLowerCase()}');
      if (response.statusCode == 200) {
        final data = response.json();
        final machines = data['machines'] as List? ?? [];
        final learnedBy = data['learned_by_pokemon'] as List? ?? [];

        // Get learn methods for each Pokemon
        final pokemonList = <Map<String, dynamic>>[];
        for (var pokemon in learnedBy) {
          pokemonList.add({
            'name': pokemon['name'] as String,
            'url': pokemon['url'] as String,
          });
        }

        setState(() {
          _moveData = {
            'name': data['name'],
            'type': data['type']?['name'] ?? 'normal',
            'power': data['power'],
            'accuracy': data['accuracy'],
            'pp': data['pp'],
            'category': data['damage_class']?['name'] ?? 'status',
            'effect': _getEffectText(data),
            'tmCount': machines.length,
          };
          _pokemonList = pokemonList;
          _loadingResults = false;
        });
      }
    } catch (e) {
      setState(() { _loadingResults = false; });
    }
  }

  String _getEffectText(Map<String, dynamic> data) {
    final entries = data['effect_entries'] as List? ?? [];
    for (var entry in entries) {
      if (entry['language']?['name'] == 'en') {
        return entry['short_effect'] ?? '';
      }
    }
    return '';
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Move → Pokemon'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Autocomplete<String>(
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return const Iterable.empty();
                      return _moveNames.where((n) => n.contains(v.text.toLowerCase())).take(15);
                    },
                    onSelected: _loadMoveDetails,
                    displayStringForOption: _formatName,
                    fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                      controller: ctrl, focusNode: focus,
                      decoration: const InputDecoration(
                        hintText: 'Search a move...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                if (_moveData != null) _buildMoveInfo(),
                if (_loadingResults)
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                if (!_loadingResults && _pokemonList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('${_pokemonList.length} Pokemon can learn this move',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (!_loadingResults)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _pokemonList.length,
                      itemBuilder: (context, index) {
                        final pokemon = _pokemonList[index];
                        final id = PokeApiService.extractIdFromUrl(pokemon['url']);
                        return ListTile(
                          leading: id != null ? Image.network(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                            width: 40, height: 40,
                            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon),
                          ) : const Icon(Icons.catching_pokemon),
                          title: Text(_formatName(pokemon['name']),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('#${id ?? "?"}'),
                          dense: true,
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildMoveInfo() {
    final m = _moveData!;
    final type = (m['type'] as String);
    final typeTitle = type[0].toUpperCase() + type.substring(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (AppTheme.typeColors[typeTitle] ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.typeColors[typeTitle] ?? Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.typeColors[typeTitle], borderRadius: BorderRadius.circular(8)),
                child: Text(typeTitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(_formatName(m['category']),
                style: const TextStyle(fontStyle: FontStyle.italic)),
              const Spacer(),
              if (m['power'] != null) Text('Pwr: ${m['power']}  '),
              if (m['accuracy'] != null) Text('Acc: ${m['accuracy']}  '),
              Text('PP: ${m['pp']}'),
            ],
          ),
          if ((m['effect'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(m['effect'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}
