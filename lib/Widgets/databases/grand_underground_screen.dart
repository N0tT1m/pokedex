import 'package:flutter/material.dart';
import '../pokemon/pokemon_detail_sheet.dart';
import '../../data/grand_underground_data.dart';

class GrandUndergroundScreen extends StatefulWidget {
  const GrandUndergroundScreen({Key? key}) : super(key: key);

  @override
  State<GrandUndergroundScreen> createState() => _GrandUndergroundScreenState();
}

class _GrandUndergroundScreenState extends State<GrandUndergroundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedHideaway;
  String _availabilityFilter = 'all'; // 'all', 'start', 'defog', 'strength', '7badges', 'waterfall', 'national'
  String _versionFilter = 'both'; // 'both', 'BD', 'SP'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedHideaway ?? 'Grand Underground'),
        backgroundColor: Colors.blueGrey[800],
        leading: _selectedHideaway != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedHideaway = null),
              )
            : null,
        bottom: _selectedHideaway == null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Hideaways'),
                  Tab(text: 'Levels'),
                ],
              )
            : null,
      ),
      body: _selectedHideaway != null
          ? _buildHideawayDetail(_selectedHideaway!)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHideawayList(),
                _buildLevelsTab(),
              ],
            ),
    );
  }

  // ===========================================================
  // HIDEAWAY LIST TAB
  // ===========================================================
  Widget _buildHideawayList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search hideaways or Pokemon...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        // Version filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('Version: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              _versionChip('Both', 'both'),
              const SizedBox(width: 4),
              _versionChip('Diamond', 'BD'),
              const SizedBox(width: 4),
              _versionChip('Pearl', 'SP'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filteredHideaways.length,
            itemBuilder: (context, index) {
              final hideaway = _filteredHideaways[index];
              final count = _getFilteredPokemon(hideaway).length;
              final icon = _biomeIcon(hideaway.biome);
              final color = _biomeColor(hideaway.biome);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  title: Text(hideaway.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${hideaway.biome}  |  ${hideaway.size}  |  $count Pokemon',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selectedHideaway = hideaway.name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Hideaway> get _filteredHideaways {
    if (_searchQuery.isEmpty) return grandUndergroundHideaways;
    return grandUndergroundHideaways.where((h) {
      if (h.name.toLowerCase().contains(_searchQuery)) return true;
      if (h.biome.toLowerCase().contains(_searchQuery)) return true;
      return _getFilteredPokemon(h)
          .any((p) => p.name.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  List<UndergroundPokemon> _getFilteredPokemon(Hideaway hideaway) {
    return hideaway.pokemon.where((p) {
      if (_versionFilter != 'both' && p.version != 'both' && p.version != _versionFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _versionChip(String label, String value) {
    final selected = _versionFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: value == 'BD'
          ? Colors.blue
          : value == 'SP'
              ? Colors.pink
              : Colors.blueGrey,
      onSelected: (_) => setState(() => _versionFilter = value),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // ===========================================================
  // HIDEAWAY DETAIL
  // ===========================================================
  Widget _buildHideawayDetail(String hideawayName) {
    final hideaway = grandUndergroundHideaways.firstWhere((h) => h.name == hideawayName);
    final allPokemon = _getFilteredPokemon(hideaway);
    final color = _biomeColor(hideaway.biome);

    // Group by availability tier
    final grouped = <String, List<UndergroundPokemon>>{};
    for (final tier in availabilityTiers) {
      final key = tier['key']!;
      final matching = allPokemon.where((p) => p.availability == key).toList();
      if (matching.isNotEmpty) grouped[key] = matching;
    }

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: color.withValues(alpha: 0.85),
          child: Column(
            children: [
              Text(hideaway.biome,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text('${hideaway.size} hideaway  |  ${allPokemon.length} Pokemon',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              // Version filter row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _versionChip('Both', 'both'),
                  const SizedBox(width: 4),
                  _versionChip('Diamond', 'BD'),
                  const SizedBox(width: 4),
                  _versionChip('Pearl', 'SP'),
                ],
              ),
            ],
          ),
        ),
        // Pokemon grouped by availability
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: grouped.entries.map((entry) {
              final tierLabel = availabilityTiers
                  .firstWhere((t) => t['key'] == entry.key)['label']!;
              return _buildTierSection(tierLabel, entry.value, entry.key);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTierSection(
      String label, List<UndergroundPokemon> pokemon, String tierKey) {
    final tierColor = _tierColor(tierKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$label  (${pokemon.length})',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: tierColor),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.78,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: pokemon.length,
          itemBuilder: (context, index) {
            final p = pokemon[index];
            return _buildPokemonCard(p);
          },
        ),
      ],
    );
  }

  Widget _buildPokemonCard(UndergroundPokemon p) {
    return GestureDetector(
      onTap: () => showPokemonDetailSheet(context, p.apiName),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Version badge
              if (p.version != 'both')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.version == 'BD' ? Colors.blue[50] : Colors.pink[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.version == 'BD' ? 'Diamond' : 'Pearl',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: p.version == 'BD' ? Colors.blue : Colors.pink,
                    ),
                  ),
                ),
              Expanded(
                child: Image.network(
                  p.spriteUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.catching_pokemon, size: 40),
                ),
              ),
              Text(
                p.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '#${p.id.toString().padLeft(3, '0')}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // LEVELS TAB
  // ===========================================================
  Widget _buildLevelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pokemon Hideaway Levels',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Wild Pokemon levels in hideaways scale with your badge count.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...badgeLevelRanges.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Text(
                    entry.key.startsWith('Post') ? 'E4' : entry.key.replaceAll(RegExp(r'[^0-9]'), ''),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            );
          }),
          const SizedBox(height: 16),
          Card(
            color: Colors.blueGrey[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('- Place Pokemon Statues in your Secret Base to change which Pokemon appear in hideaways.',
                      style: TextStyle(fontSize: 12)),
                  Text('- Statues of a specific type increase spawn rates for that type.',
                      style: TextStyle(fontSize: 12)),
                  Text('- Shiny Statues have a stronger effect than regular ones.',
                      style: TextStyle(fontSize: 12)),
                  Text('- Rare/Legendary statues give the biggest type bonus.',
                      style: TextStyle(fontSize: 12)),
                  Text('- National Dex Pokemon only appear after obtaining the National Pokedex from Prof. Oak.',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // HELPERS
  // ===========================================================
  Color _biomeColor(String biome) {
    final b = biome.toLowerCase();
    if (b.contains('fire')) return Colors.deepOrange;
    if (b.contains('water')) return Colors.blue;
    if (b.contains('grass')) return Colors.green;
    if (b.contains('ice')) return Colors.cyan;
    if (b.contains('rock') || b.contains('ground')) return Colors.brown;
    if (b.contains('psychic') || b.contains('ghost')) return Colors.deepPurple;
    if (b.contains('poison')) return Colors.purple;
    if (b.contains('normal')) return Colors.blueGrey;
    return Colors.blueGrey;
  }

  IconData _biomeIcon(String biome) {
    final b = biome.toLowerCase();
    if (b.contains('fire')) return Icons.local_fire_department;
    if (b.contains('water')) return Icons.water_drop;
    if (b.contains('grass')) return Icons.grass;
    if (b.contains('ice')) return Icons.ac_unit;
    if (b.contains('rock') || b.contains('ground')) return Icons.terrain;
    if (b.contains('psychic') || b.contains('ghost')) return Icons.auto_awesome;
    if (b.contains('poison')) return Icons.science;
    if (b.contains('normal')) return Icons.landscape;
    return Icons.landscape;
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'start':
        return Colors.green;
      case 'defog':
        return Colors.teal;
      case 'strength':
        return Colors.orange;
      case '7badges':
        return Colors.deepOrange;
      case 'waterfall':
        return Colors.blue;
      case 'national':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

}
