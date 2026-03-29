import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class ReverseAbilityLookupScreen extends StatefulWidget {
  const ReverseAbilityLookupScreen({Key? key}) : super(key: key);

  @override
  State<ReverseAbilityLookupScreen> createState() => _ReverseAbilityLookupScreenState();
}

class _ReverseAbilityLookupScreenState extends State<ReverseAbilityLookupScreen> {
  List<String> _abilityNames = [];
  bool _isLoading = true;
  bool _loadingResults = false;
  Map<String, dynamic>? _abilityData;
  List<Map<String, dynamic>> _pokemonList = [];

  @override
  void initState() {
    super.initState();
    _loadAbilityList();
  }

  Future<void> _loadAbilityList() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/ability?limit=400');
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _abilityNames = (data['results'] as List).map((a) => a['name'] as String).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAbility(String abilityName) async {
    setState(() { _loadingResults = true; });
    try {
      final data = await PokeApiService.getAbility(abilityName.toLowerCase());
      final effectEntries = data['effect_entries'] as List? ?? [];
      String effect = '';
      for (var entry in effectEntries) {
        if (entry['language']?['name'] == 'en') {
          effect = entry['short_effect'] ?? entry['effect'] ?? '';
          break;
        }
      }

      final pokemon = (data['pokemon'] as List? ?? []).map<Map<String, dynamic>>((p) {
        return {
          'name': p['pokemon']['name'] as String,
          'url': p['pokemon']['url'] as String,
          'isHidden': p['is_hidden'] as bool,
          'slot': p['slot'],
        };
      }).toList();

      // Sort: regular abilities first, then hidden
      pokemon.sort((a, b) {
        if (a['isHidden'] != b['isHidden']) return a['isHidden'] ? 1 : -1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      setState(() {
        _abilityData = {
          'name': abilityName,
          'effect': effect,
          'generation': data['generation']?['name'] ?? 'unknown',
        };
        _pokemonList = pokemon;
        _loadingResults = false;
      });
    } catch (e) {
      setState(() { _loadingResults = false; });
    }
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ability → Pokemon'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Autocomplete<String>(
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return const Iterable.empty();
                      return _abilityNames.where((n) => n.contains(v.text.toLowerCase())).take(15);
                    },
                    onSelected: _loadAbility,
                    displayStringForOption: _formatName,
                    fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                      controller: ctrl, focusNode: focus,
                      decoration: const InputDecoration(
                        hintText: 'Search an ability...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                if (_abilityData != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatName(_abilityData!['name']),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(_abilityData!['effect'], style: const TextStyle(fontSize: 13)),
                        Text('Introduced: ${_formatName(_abilityData!['generation'])}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                if (_loadingResults)
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                if (!_loadingResults && _pokemonList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text('${_pokemonList.length} Pokemon',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${_pokemonList.where((p) => p['isHidden']).length} hidden ability',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _pokemonList.length,
                    itemBuilder: (context, index) {
                      final pokemon = _pokemonList[index];
                      final id = PokeApiService.extractIdFromUrl(pokemon['url']);
                      final isHidden = pokemon['isHidden'] as bool;

                      return ListTile(
                        leading: id != null ? Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                          width: 40, height: 40,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon),
                        ) : const Icon(Icons.catching_pokemon),
                        title: Text(_formatName(pokemon['name'])),
                        subtitle: Text('#${id ?? "?"}'),
                        trailing: isHidden
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Hidden', style: TextStyle(fontSize: 11, color: Colors.orange)),
                            )
                          : null,
                        dense: true,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
