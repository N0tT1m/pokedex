import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/saved_pokemon.dart';
import '../services/pokemon_storage_service.dart';
import 'pokemon_detail_view.dart';

class MyPokemon extends StatefulWidget {
  const MyPokemon({Key? key}) : super(key: key);

  @override
  State<MyPokemon> createState() => _MyPokemonState();
}

class _MyPokemonState extends State<MyPokemon> {
  final _storageService = PokemonStorageService();
  List<SavedPokemon> _pokemon = [];
  List<SavedPokemon> _filteredPokemon = [];
  String _searchQuery = '';
  String _sortBy = 'date'; // date, name, level, ivs

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  void _loadPokemon() {
    setState(() {
      _pokemon = _storageService.getAllPokemon();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<SavedPokemon> filtered = List.from(_pokemon);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final query = _searchQuery.toLowerCase();
        return p.speciesName.toLowerCase().contains(query) ||
            (p.nickname?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case 'level':
        filtered.sort((a, b) => b.level.compareTo(a.level));
        break;
      case 'ivs':
        filtered.sort((a, b) => b.totalIVs.compareTo(a.totalIVs));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.caughtDate.compareTo(a.caughtDate));
        break;
    }

    setState(() {
      _filteredPokemon = filtered;
    });
  }

  Future<void> _deletePokemon(SavedPokemon pokemon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pokemon'),
        content: Text('Are you sure you want to delete ${pokemon.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deletePokemon(pokemon.id);
      _loadPokemon();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pokemon.displayName} deleted')),
        );
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Sort by Date Caught'),
              selected: _sortBy == 'date',
              onTap: () {
                setState(() => _sortBy = 'date');
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Sort by Name'),
              selected: _sortBy == 'name',
              onTap: () {
                setState(() => _sortBy = 'name');
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Sort by Level'),
              selected: _sortBy == 'level',
              onTap: () {
                setState(() => _sortBy = 'level');
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Sort by IVs'),
              selected: _sortBy == 'ivs',
              onTap: () {
                setState(() => _sortBy = 'ivs');
                _applyFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    final stats = _storageService.getStatistics();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Collection Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Pokemon', '${stats['totalPokemon']}'),
            _buildStatRow('Unique Species', '${stats['uniqueSpecies']}'),
            _buildStatRow('Teams', '${stats['totalTeams']}'),
            _buildStatRow('Shiny Pokemon', '${stats['shinyCount']}'),
            _buildStatRow(
              'Average IVs',
              '${(stats['averageIVs'] as double).toStringAsFixed(1)} / 186',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pokemon'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatistics,
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Pokemon...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.red,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          if (_filteredPokemon.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.catching_pokemon,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No Pokemon saved yet'
                          : 'No Pokemon found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Use the IV Checker to add Pokemon',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPokemon.length,
                itemBuilder: (context, index) {
                  final pokemon = _filteredPokemon[index];
                  return _buildPokemonCard(pokemon);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPokemonCard(SavedPokemon pokemon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailView(pokemon: pokemon),
            ),
          ).then((_) => _loadPokemon());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Pokemon sprite
              if (pokemon.spriteUrl != null)
                CachedNetworkImage(
                  imageUrl: pokemon.spriteUrl!,
                  width: 64,
                  height: 64,
                  placeholder: (context, url) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.catching_pokemon,
                    size: 64,
                  ),
                )
              else
                const Icon(Icons.catching_pokemon, size: 64),
              const SizedBox(width: 16),
              // Pokemon info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pokemon.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pokemon.isShiny) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                        ],
                        if (pokemon.gender != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            pokemon.gender == 'Male'
                                ? Icons.male
                                : pokemon.gender == 'Female'
                                    ? Icons.female
                                    : Icons.transgender,
                            size: 20,
                            color: pokemon.gender == 'Male'
                                ? Colors.blue
                                : pokemon.gender == 'Female'
                                    ? Colors.pink
                                    : Colors.grey,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${pokemon.level} • ${pokemon.nature}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatChip(
                          'IVs: ${pokemon.totalIVs}/186',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          'EVs: ${pokemon.totalEVs}/510',
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailView(pokemon: pokemon),
                      ),
                    ).then((_) => _loadPokemon());
                  } else if (value == 'delete') {
                    _deletePokemon(pokemon);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
