import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class AbilityDatabaseScreen extends StatefulWidget {
  const AbilityDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<AbilityDatabaseScreen> createState() => _AbilityDatabaseScreenState();
}

class _AbilityDatabaseScreenState extends State<AbilityDatabaseScreen> {
  List<Map<String, dynamic>> _allAbilities = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedAbility;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadAbilities();
  }

  Future<void> _loadAbilities() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/ability?limit=400');
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _allAbilities = List<Map<String, dynamic>>.from(data['results']).map((a) {
            final name = a['name'] as String;
            return {
              'name': name,
              'displayName': name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
              'url': a['url'],
            };
          }).toList();
          _filtered = _allAbilities;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Could not load abilities'; _isLoading = false; });
    }
  }

  Future<void> _loadAbilityDetail(String name) async {
    setState(() => _isLoadingDetail = true);
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/ability/$name');
      if (response.statusCode == 200) {
        setState(() {
          _selectedAbility = response.json();
          _isLoadingDetail = false;
        });
      } else {
        setState(() => _isLoadingDetail = false);
      }
    } catch (e) {
      setState(() => _isLoadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedAbility != null ? _formatName(_selectedAbility!['name']) : 'Ability Database'),
        backgroundColor: Colors.red,
        leading: _selectedAbility != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedAbility = null))
            : null,
      ),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : _selectedAbility != null ? _buildDetail() : _buildList(),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadAbilities(); }, child: const Text('Retry')),
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
              hintText: 'Search abilities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
                _filtered = _allAbilities.where((a) =>
                    a['displayName'].toLowerCase().contains(v.toLowerCase())).toList();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${_filtered.length} abilities', style: TextStyle(color: Colors.grey.shade600)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final ability = _filtered[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  title: Text(ability['displayName']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadAbilityDetail(ability['name']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetail() {
    final ability = _selectedAbility!;
    final effectEntries = ability['effect_entries'] as List? ?? [];
    String effect = '';
    String shortEffect = '';
    for (var entry in effectEntries) {
      if (entry['language']?['name'] == 'en') {
        effect = entry['effect'] ?? '';
        shortEffect = entry['short_effect'] ?? '';
      }
    }

    final flavorEntries = ability['flavor_text_entries'] as List? ?? [];
    String flavorText = '';
    for (var entry in flavorEntries.reversed) {
      if (entry['language']?['name'] == 'en') {
        flavorText = ((entry['flavor_text'] as String?) ?? '').replaceAll('\n', ' ');
        break;
      }
    }

    final pokemon = ability['pokemon'] as List? ?? [];
    final generation = ability['generation']?['name'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatName(ability['name']),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (generation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Introduced in ${_formatName(generation)}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 12),
                  if (shortEffect.isNotEmpty)
                    Text(shortEffect, style: const TextStyle(fontSize: 16)),
                  if (flavorText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(flavorText, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ),
          if (effect.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detailed Effect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(effect, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pokemon with this ability (${pokemon.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...pokemon.take(30).map((p) {
                    final pName = _formatName(p['pokemon']['name']);
                    final isHidden = p['is_hidden'] == true;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(pName),
                          if (isHidden) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Hidden', style: TextStyle(fontSize: 10, color: Colors.purple)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (pokemon.length > 30)
                    Text('...and ${pokemon.length - 30} more',
                        style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }
}
