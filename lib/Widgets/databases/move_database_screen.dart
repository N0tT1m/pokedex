import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

class MoveDatabaseScreen extends StatefulWidget {
  const MoveDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<MoveDatabaseScreen> createState() => _MoveDatabaseScreenState();
}

class _MoveDatabaseScreenState extends State<MoveDatabaseScreen> {
  List<Map<String, dynamic>> _allMoves = [];
  List<Map<String, dynamic>> _filteredMoves = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _filterType;
  String? _filterCategory;
  Map<String, dynamic>? _selectedMove;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/move?limit=1000');
      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results']);
        setState(() {
          _allMoves = results.map((m) {
            final name = m['name'] as String;
            return {
              'name': name,
              'displayName': name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
              'url': m['url'],
            };
          }).toList();
          _filteredMoves = _allMoves;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Server returned ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not load moves'; _isLoading = false; });
    }
  }

  Future<void> _loadMoveDetail(String name) async {
    setState(() => _isLoadingDetail = true);
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/move/$name');
      if (response.statusCode == 200) {
        setState(() {
          _selectedMove = response.json();
          _isLoadingDetail = false;
        });
      } else {
        setState(() => _isLoadingDetail = false);
      }
    } catch (e) {
      setState(() => _isLoadingDetail = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMoves = _allMoves.where((m) {
        final name = m['displayName'] as String;
        if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Move Database'),
        backgroundColor: Colors.red,
        actions: [
          if (_selectedMove != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedMove = null),
            ),
        ],
      ),
      body: _selectedMove != null ? _buildMoveDetail() : _buildMoveList(),
    );
  }

  Widget _buildMoveList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadMoves(); }, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search moves...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) {
              _searchQuery = v;
              _applyFilters();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${_filteredMoves.length} moves', style: TextStyle(color: Colors.grey.shade600)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filteredMoves.length,
            itemBuilder: (context, index) {
              final move = _filteredMoves[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  title: Text(move['displayName']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadMoveDetail(move['name']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoveDetail() {
    if (_isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final move = _selectedMove!;
    final name = (move['name'] as String).split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    final type = move['type']?['name'] ?? 'unknown';
    final typeCap = type[0].toUpperCase() + type.substring(1);
    final category = move['damage_class']?['name'] ?? 'status';
    final power = move['power'];
    final accuracy = move['accuracy'];
    final pp = move['pp'];
    final effectEntries = move['effect_entries'] as List? ?? [];
    String effect = '';
    for (var entry in effectEntries) {
      if (entry['language']['name'] == 'en') {
        effect = entry['short_effect'] ?? entry['effect'] ?? '';
        break;
      }
    }
    final effectChance = move['effect_chance'];
    if (effectChance != null) {
      effect = effect.replaceAll('\$effect_chance', effectChance.toString());
    }

    // Flavor text
    final flavorEntries = move['flavor_text_entries'] as List? ?? [];
    String flavorText = '';
    for (var entry in flavorEntries.reversed) {
      if (entry['language']['name'] == 'en') {
        flavorText = (entry['flavor_text'] as String).replaceAll('\n', ' ');
        break;
      }
    }

    // Learned by Pokemon
    final learnedBy = move['learned_by_pokemon'] as List? ?? [];

    // TM/HM info
    final machines = move['machines'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.typeColors[typeCap] ?? Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(typeCap, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: category == 'physical' ? Colors.orange : category == 'special' ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn('Power', power?.toString() ?? '-'),
                      _statColumn('Accuracy', accuracy != null ? '$accuracy%' : '-'),
                      _statColumn('PP', pp?.toString() ?? '-'),
                      _statColumn('Priority', move['priority']?.toString() ?? '0'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Effect
          if (effect.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Effect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(effect),
                    if (flavorText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(flavorText, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
          // TM/HM
          if (machines.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TM/HM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...machines.take(10).map((m) {
                      final version = m['version_group']?['name'] ?? '';
                      return Text(
                        '${_formatName(version)}',
                        style: const TextStyle(fontSize: 12),
                      );
                    }),
                    if (machines.length > 10) Text('...and ${machines.length - 10} more'),
                  ],
                ),
              ),
            ),
          // Learned by
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learned by ${learnedBy.length} Pokemon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: learnedBy.take(50).map((p) {
                      final pName = _formatName(p['name']);
                      return Chip(
                        label: Text(pName, style: const TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                  if (learnedBy.length > 50) Text('...and ${learnedBy.length - 50} more'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }
}
