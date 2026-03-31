import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class ItemLocationScreen extends StatefulWidget {
  const ItemLocationScreen({Key? key}) : super(key: key);

  @override
  State<ItemLocationScreen> createState() => _ItemLocationScreenState();
}

class _ItemLocationScreenState extends State<ItemLocationScreen> {
  List<String> _games = [];
  String? _selectedGame;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoadingGames = true;
  bool _isLoadingItems = false;
  String? _error;
  String _searchQuery = '';
  String _selectedMethod = 'All';

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/item-locations/games');
      if (response.statusCode == 200) {
        final data = response.json();
        final games = List<String>.from(data['games'] ?? []);
        setState(() {
          _games = games;
          _isLoadingGames = false;
          if (games.isNotEmpty) {
            _selectedGame = games.first;
            _loadItems(games.first);
          }
        });
      } else {
        setState(() { _error = 'Could not load games'; _isLoadingGames = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not load games'; _isLoadingGames = false; });
    }
  }

  Future<void> _loadItems(String game) async {
    setState(() { _isLoadingItems = true; _error = null; });
    try {
      final encoded = Uri.encodeComponent(game);
      final response = await Requests.get('${PokeApiService.baseUrl}/item-locations?game=$encoded');
      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results'] ?? []);
        setState(() {
          _locations = results;
          _isLoadingItems = false;
          _applyFilter();
        });
      } else {
        setState(() { _locations = []; _isLoadingItems = false; _applyFilter(); });
      }
    } catch (e) {
      setState(() { _locations = []; _isLoadingItems = false; _applyFilter(); });
    }
  }

  List<String> get _methods {
    final set = <String>{'All'};
    for (final loc in _locations) {
      final m = loc['method']?.toString() ?? '';
      if (m.isNotEmpty) set.add(m);
    }
    return set.toList();
  }

  void _applyFilter() {
    setState(() {
      _filtered = _locations.where((loc) {
        final itemName = loc['item_name']?.toString() ?? '';
        final location = loc['location']?.toString() ?? '';
        final method = loc['method']?.toString() ?? '';
        if (_searchQuery.isNotEmpty) {
          if (!itemName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !location.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }
        if (_selectedMethod != 'All' && method != _selectedMethod) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Locations'), backgroundColor: Colors.red),
      body: _isLoadingGames
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGame,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Game', border: OutlineInputBorder()),
                    items: _games.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() { _selectedGame = v; _selectedMethod = 'All'; _searchQuery = ''; });
                      _loadItems(v);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search item or location...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) { _searchQuery = v; _applyFilter(); },
                  ),
                ),
                if (_methods.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: _methods.map((m) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(m),
                          selected: _selectedMethod == m,
                          onSelected: (_) { setState(() => _selectedMethod = m); _applyFilter(); },
                        ),
                      )).toList(),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Expanded(
                  child: _isLoadingItems
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                _locations.isEmpty ? 'No data for this game' : 'No results',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final loc = _filtered[index];
                                final itemName = loc['item_name']?.toString() ?? '';
                                final location = loc['location']?.toString() ?? '';
                                final method = loc['method']?.toString() ?? '';
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _methodColor(method),
                                      child: const Icon(Icons.backpack, color: Colors.white, size: 18),
                                    ),
                                    title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(location, style: const TextStyle(fontSize: 12)),
                                        if (method.isNotEmpty)
                                          Text(method, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                    isThreeLine: method.isNotEmpty,
                                    dense: true,
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Color _methodColor(String method) {
    switch (method) {
      case 'Finite': return Colors.purple;
      case 'Repeatable': return Colors.blue;
      case 'Finite & Repeatable': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
