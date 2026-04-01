import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';
import '../../services/evolution_service.dart';
import '../pokemon/pokemon_detail_sheet.dart';

class EvolutionMethodsScreen extends StatefulWidget {
  const EvolutionMethodsScreen({Key? key}) : super(key: key);

  @override
  State<EvolutionMethodsScreen> createState() => _EvolutionMethodsScreenState();
}

class _EvolutionMethodsScreenState extends State<EvolutionMethodsScreen> {
  List<String> _pokemonNames = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _evolutions = [];
  String? _selectedPokemon;
  bool _loadingEvos = false;

  @override
  void initState() {
    super.initState();
    _loadPokemonList();
  }

  Future<void> _loadPokemonList() async {
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

  Future<void> _loadEvolutions(String name) async {
    setState(() { _loadingEvos = true; _selectedPokemon = name; });
    try {
      final evos = await EvolutionService.getEvolutionDetails(name);
      setState(() { _evolutions = evos; _loadingEvos = false; });
    } catch (e) {
      setState(() { _evolutions = []; _loadingEvos = false; });
    }
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolution Methods'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Autocomplete<String>(
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return const Iterable.empty();
                      return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                    },
                    onSelected: _loadEvolutions,
                    fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                      controller: ctrl, focusNode: focus,
                      decoration: const InputDecoration(
                        hintText: 'Search Pokemon...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                if (_loadingEvos) const Center(child: CircularProgressIndicator()),
                if (!_loadingEvos && _selectedPokemon != null && _evolutions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('This Pokemon does not evolve.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _evolutions.length,
                    itemBuilder: (context, index) {
                      final evo = _evolutions[index];
                      final method = EvolutionService.describeMethod(evo);
                      final fromId = PokeApiService.extractIdFromUrl(
                        '${PokeApiService.baseUrl}/pokemon-species/${evo['fromApi']}/');

                      return GestureDetector(
                        onTap: () => showPokemonDetailSheet(context, evo['toApi'] ?? evo['to']),
                        child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              if (fromId != null)
                                Image.network(
                                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$fromId.png',
                                  width: 56, height: 56,
                                  errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56),
                                ),
                              const Icon(Icons.arrow_forward, color: Colors.grey),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${evo['from']} → ${evo['to']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(method, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
