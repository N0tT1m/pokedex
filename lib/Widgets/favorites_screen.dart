import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/favorite_pokemon.dart';
import '../services/pokeapi_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Box<FavoritePokemon>? _box;
  List<String> _pokemonNames = [];
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<FavoritePokemon>('favorites');
    try {
      final list = await PokeApiService.getPokemonList(limit: 1025);
      _pokemonNames = list.map((p) => p['name'] as String).toList();
    } catch (_) {}
    setState(() => _isLoadingNames = false);
  }

  List<FavoritePokemon> get _favorites => _box?.values.toList() ?? [];

  Future<void> _addFavorite() async {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? selectedName;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Favorite'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                optionsBuilder: (v) {
                  if (v.text.isEmpty) return const Iterable.empty();
                  return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                },
                onSelected: (name) {
                  selectedName = name;
                  nameCtrl.text = name;
                },
                fieldViewBuilder: (ctx, ctrl, focus, submit) {
                  nameCtrl.text = ctrl.text;
                  return TextField(
                    controller: ctrl,
                    focusNode: focus,
                    decoration: const InputDecoration(labelText: 'Pokemon Name', border: OutlineInputBorder()),
                    onChanged: (v) {
                      selectedName = v.toLowerCase();
                      nameCtrl.text = v.toLowerCase();
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = selectedName ?? nameCtrl.text.toLowerCase();
      if (name.isNotEmpty) {
        // Check for duplicate
        final exists = _favorites.any((f) => f.speciesName == name);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Already in favorites')),
            );
          }
          return;
        }

        final fav = FavoritePokemon(
          speciesName: name,
          addedDate: DateTime.now(),
          notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
          spriteUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${_getDexNumber(name)}.png',
        );
        await _box!.add(fav);
        setState(() {});
      }
    }
  }

  int _getDexNumber(String name) {
    final idx = _pokemonNames.indexOf(name.toLowerCase());
    return idx >= 0 ? idx + 1 : 1;
  }

  Future<void> _removeFavorite(int index) async {
    await _box!.deleteAt(index);
    setState(() {});
  }

  String _capitalize(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), backgroundColor: Colors.red),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
        onPressed: _addFavorite,
      ),
      body: _box == null
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No favorites yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text('Tap + to add your favorite Pokemon!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    return Card(
                      child: ListTile(
                        leading: fav.spriteUrl != null
                            ? Image.network(fav.spriteUrl!, width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon))
                            : const Icon(Icons.catching_pokemon),
                        title: Text(_capitalize(fav.speciesName), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: fav.notes != null ? Text(fav.notes!) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeFavorite(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
