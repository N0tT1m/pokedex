import 'package:flutter/material.dart';
import 'package:requests/requests.dart';

class ItemDatabaseScreen extends StatefulWidget {
  const ItemDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<ItemDatabaseScreen> createState() => _ItemDatabaseScreenState();
}

class _ItemDatabaseScreenState extends State<ItemDatabaseScreen> {
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedItem;
  bool _isLoadingDetail = false;

  static const categories = ['All', 'Pokeballs', 'Medicine', 'Berries', 'Held Items', 'TMs', 'Evolution', 'Key Items'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final response = await Requests.get('https://pokeapi.co/api/v2/item?limit=2000');
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _allItems = List<Map<String, dynamic>>.from(data['results']).map((i) {
            final name = i['name'] as String;
            return {
              'name': name,
              'displayName': name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
              'url': i['url'],
            };
          }).toList();
          _filtered = _allItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Could not load items'; _isLoading = false; });
    }
  }

  Future<void> _loadItemDetail(String url) async {
    setState(() => _isLoadingDetail = true);
    try {
      final response = await Requests.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _selectedItem = response.json();
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingDetail = false);
    }
  }

  void _filter() {
    setState(() {
      _filtered = _allItems.where((item) {
        if (_searchQuery.isNotEmpty &&
            !item['displayName'].toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        if (_selectedCategory != 'All') {
          final name = item['name'] as String;
          switch (_selectedCategory) {
            case 'Pokeballs':
              return name.contains('ball') && !name.contains('snow');
            case 'Berries':
              return name.contains('berry');
            case 'TMs':
              return name.startsWith('tm') || name.startsWith('hm') || name.startsWith('tr');
            case 'Evolution':
              return _evolutionItems.contains(name);
            case 'Medicine':
              return _medicineItems.any((m) => name.contains(m));
            case 'Key Items':
              return false;
            case 'Held Items':
              return _heldItems.any((h) => name.contains(h));
          }
        }
        return true;
      }).toList();
    });
  }

  static const _evolutionItems = [
    'fire-stone', 'water-stone', 'thunder-stone', 'leaf-stone', 'moon-stone',
    'sun-stone', 'shiny-stone', 'dusk-stone', 'dawn-stone', 'ice-stone',
    'oval-stone', 'kings-rock', 'metal-coat', 'dragon-scale', 'upgrade',
    'dubious-disc', 'protector', 'electirizer', 'magmarizer', 'reaper-cloth',
    'prism-scale', 'whipped-dream', 'sachet', 'razor-claw', 'razor-fang',
    'deep-sea-tooth', 'deep-sea-scale', 'linking-cord', 'black-augurite',
    'peat-block', 'auspicious-armor', 'malicious-armor', 'chipped-pot',
    'cracked-pot', 'galarica-cuff', 'galarica-wreath', 'sweet-apple',
    'tart-apple', 'strawberry-sweet', 'love-sweet', 'berry-sweet',
    'clover-sweet', 'flower-sweet', 'star-sweet', 'ribbon-sweet',
    'scroll-of-darkness', 'scroll-of-waters', 'syrupy-apple',
  ];

  static const _medicineItems = ['potion', 'heal', 'revive', 'elixir', 'ether', 'antidote', 'cure', 'remedy'];
  static const _heldItems = ['orb', 'band', 'scarf', 'lens', 'specs', 'vest', 'belt', 'plate', 'gem', 'incense'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedItem != null ? _formatName(_selectedItem!['name']) : 'Item Database'),
        backgroundColor: Colors.red,
        leading: _selectedItem != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedItem = null))
            : null,
      ),
      body: _selectedItem != null ? _buildDetail() : _buildList(),
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
            ElevatedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadItems(); }, child: const Text('Retry')),
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
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) {
              _searchQuery = v;
              _filter();
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: Colors.red,
                  onSelected: (_) {
                    _selectedCategory = cat;
                    _filter();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${_filtered.length} items', style: TextStyle(color: Colors.grey.shade600)),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final item = _filtered[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  title: Text(item['displayName']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadItemDetail(item['url']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetail() {
    if (_isLoadingDetail) return const Center(child: CircularProgressIndicator());

    final item = _selectedItem!;
    final effectEntries = item['effect_entries'] as List? ?? [];
    String effect = '';
    String shortEffect = '';
    for (var entry in effectEntries) {
      if (entry['language']['name'] == 'en') {
        effect = entry['effect'] ?? '';
        shortEffect = entry['short_effect'] ?? '';
      }
    }

    final flavorEntries = item['flavor_text_entries'] as List? ?? [];
    String flavorText = '';
    for (var entry in flavorEntries.reversed) {
      if (entry['language']['name'] == 'en') {
        flavorText = (entry['flavor_text'] as String).replaceAll('\n', ' ');
        break;
      }
    }

    final category = item['category']?['name'] ?? '';
    final cost = item['cost'] ?? 0;
    final spriteUrl = item['sprites']?['default'];
    final heldBy = item['held_by_pokemon'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (spriteUrl != null)
                    Image.network(spriteUrl, width: 64, height: 64,
                        errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 64)),
                  Text(_formatName(item['name']),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (category.isNotEmpty) Text(_formatName(category), style: const TextStyle(color: Colors.grey)),
                  if (cost > 0) Text('Cost: $cost', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  if (shortEffect.isNotEmpty) Text(shortEffect, textAlign: TextAlign.center),
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
                    const Text('Effect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(effect, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          if (flavorText.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(flavorText, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          if (heldBy.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Held by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...heldBy.map((p) => Text(_formatName(p['pokemon']['name']))),
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
