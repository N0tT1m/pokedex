import 'package:flutter/material.dart';

class ItemLocationScreen extends StatefulWidget {
  const ItemLocationScreen({Key? key}) : super(key: key);

  @override
  State<ItemLocationScreen> createState() => _ItemLocationScreenState();
}

class _ItemLocationScreenState extends State<ItemLocationScreen> {
  String _selectedGame = 'Scarlet / Violet';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const Map<String, Map<String, List<Map<String, String>>>> _itemLocations = {
    'Scarlet / Violet': {
      'Evolution': [
        {'name': 'Fire Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Water Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Thunder Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Leaf Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Ice Stone', 'location': 'Delibird Presents (Levincia) after 3 Gym Badges'},
        {'name': 'Moon Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Sun Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Dusk Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Dawn Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Shiny Stone', 'location': 'Delibird Presents (Mesagoza) after 3 Gym Badges'},
        {'name': 'Razor Claw', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Razor Fang', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Metal Coat', 'location': 'Delibird Presents (Levincia) after 3 Gym Badges'},
        {'name': 'Dragon Scale', 'location': 'Delibird Presents (Levincia) after 3 Gym Badges'},
        {'name': 'Prism Scale', 'location': 'Delibird Presents (Levincia) after 3 Gym Badges'},
        {'name': 'Reaper Cloth', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Linking Cord', 'location': 'Porto Marinada auction / Tera Raid rewards'},
      ],
      'Held': [
        {'name': 'Leftovers', 'location': 'Porto Marinada auction / wild Munchlax (5%)'},
        {'name': 'Choice Band', 'location': 'Delibird Presents (Mesagoza) after 6 Gym Badges'},
        {'name': 'Choice Specs', 'location': 'Delibird Presents (Mesagoza) after 6 Gym Badges'},
        {'name': 'Choice Scarf', 'location': 'Delibird Presents (Mesagoza) after 6 Gym Badges'},
        {'name': 'Life Orb', 'location': 'Levincia City / Delibird Presents after 6 Badges'},
        {'name': 'Focus Sash', 'location': 'Delibird Presents (Mesagoza) after 6 Gym Badges'},
        {'name': 'Assault Vest', 'location': 'Delibird Presents (Mesagoza) after 6 Gym Badges'},
        {'name': 'Rocky Helmet', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Eviolite', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Black Sludge', 'location': 'Wild Grimer/Muk (5%)'},
        {'name': 'Toxic Orb', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Flame Orb', 'location': 'Delibird Presents (Levincia) after 6 Gym Badges'},
        {'name': 'Light Clay', 'location': 'Delibird Presents (Levincia) after 3 Gym Badges'},
        {'name': 'Heavy-Duty Boots', 'location': 'Delibird Presents (Mesagoza) after 4 Gym Badges'},
        {'name': 'Weakness Policy', 'location': 'Delibird Presents (Mesagoza) after 6 Gym Badges'},
      ],
      'EV Training': [
        {'name': 'Power Weight', 'location': 'Delibird Presents (Mesagoza) after 4 Badges - HP EVs'},
        {'name': 'Power Bracer', 'location': 'Delibird Presents (Mesagoza) after 4 Badges - Atk EVs'},
        {'name': 'Power Belt', 'location': 'Delibird Presents (Mesagoza) after 4 Badges - Def EVs'},
        {'name': 'Power Lens', 'location': 'Delibird Presents (Mesagoza) after 4 Badges - SpA EVs'},
        {'name': 'Power Band', 'location': 'Delibird Presents (Mesagoza) after 4 Badges - SpD EVs'},
        {'name': 'Power Anklet', 'location': 'Delibird Presents (Mesagoza) after 4 Badges - Spe EVs'},
        {'name': 'Macho Brace', 'location': 'Doubles all EV gains - not available in SV'},
      ],
      'Battle': [
        {'name': 'Ability Capsule', 'location': 'Chansey Supply shops after 6 Gym Badges'},
        {'name': 'Ability Patch', 'location': '6-Star Tera Raid rewards'},
        {'name': 'Bottle Cap', 'location': 'Delibird Presents after beating the game'},
        {'name': 'Gold Bottle Cap', 'location': '6-Star Tera Raid rewards (rare)'},
        {'name': 'Nature Mints', 'location': 'Chansey Supply shops / Tera Raids'},
      ],
    },
    'Sword / Shield': {
      'Evolution': [
        {'name': 'Fire Stone', 'location': 'Lake of Outrage (Dusty Bowl)'},
        {'name': 'Water Stone', 'location': 'Lake of Outrage / Route 2'},
        {'name': 'Thunder Stone', 'location': 'Lake of Outrage / Route 4'},
        {'name': 'Leaf Stone', 'location': 'Lake of Outrage / Turffield'},
        {'name': 'Ice Stone', 'location': 'Lake of Outrage / Route 9'},
        {'name': 'Sweet Apple', 'location': 'Hammerlocke (trade) - Sword exclusive method'},
        {'name': 'Tart Apple', 'location': 'Hammerlocke (trade) - Shield exclusive method'},
        {'name': 'Cracked Pot', 'location': 'Stow-on-Side - for Sinistea'},
        {'name': 'Chipped Pot', 'location': 'Stow-on-Side bargain shop (rare) - for Antique Sinistea'},
      ],
      'Held': [
        {'name': 'Leftovers', 'location': 'Wild Area (Motostoke Riverbank)'},
        {'name': 'Choice Band', 'location': 'Hammerlocke BP Shop (25 BP)'},
        {'name': 'Choice Specs', 'location': 'Hammerlocke BP Shop (25 BP)'},
        {'name': 'Choice Scarf', 'location': 'Hammerlocke BP Shop (25 BP)'},
        {'name': 'Life Orb', 'location': 'Wyndon BP Shop (25 BP) / Stow-on-Side'},
        {'name': 'Focus Sash', 'location': 'Hammerlocke BP Shop (15 BP)'},
        {'name': 'Assault Vest', 'location': 'Hammerlocke BP Shop (25 BP)'},
        {'name': 'Eviolite', 'location': 'Ballonlea'},
      ],
      'Battle': [
        {'name': 'Ability Capsule', 'location': 'Battle Tower (50 BP)'},
        {'name': 'Ability Patch', 'location': 'Max Lair (Dynamax Adventures) reward'},
        {'name': 'Bottle Cap', 'location': 'Battle Tower (25 BP) / Digging Duo'},
        {'name': 'Gold Bottle Cap', 'location': 'Battle Tower (50 BP) / rare Digging Duo'},
        {'name': 'Nature Mints', 'location': 'Battle Tower (50 BP each)'},
      ],
    },
    'Brilliant Diamond / Shining Pearl': {
      'Evolution': [
        {'name': 'Fire Stone', 'location': 'Fuego Ironworks / Grand Underground'},
        {'name': 'Water Stone', 'location': 'Route 213 / Grand Underground'},
        {'name': 'Thunder Stone', 'location': 'Sunyshore City / Grand Underground'},
        {'name': 'Leaf Stone', 'location': 'Floaroma Meadow / Grand Underground'},
        {'name': 'Dusk Stone', 'location': 'Galactic Warehouse / Grand Underground'},
        {'name': 'Dawn Stone', 'location': 'Mt. Coronet / Grand Underground'},
        {'name': 'Razor Fang', 'location': 'Battle Park (5 BP) / Route 225'},
        {'name': 'Razor Claw', 'location': 'Battle Park (5 BP) / Victory Road'},
        {'name': 'Reaper Cloth', 'location': 'Route 229 / Battle Park'},
        {'name': 'Electirizer', 'location': 'Wild Elekid (5%) - Route 204'},
        {'name': 'Magmarizer', 'location': 'Wild Magby (5%) - Route 227'},
      ],
      'Held': [
        {'name': 'Leftovers', 'location': 'Victory Road'},
        {'name': 'Choice Band', 'location': 'Battle Park (48 BP)'},
        {'name': 'Choice Specs', 'location': 'Battle Park (48 BP)'},
        {'name': 'Choice Scarf', 'location': 'Battle Park (48 BP)'},
        {'name': 'Life Orb', 'location': 'Stark Mountain / Battle Park (48 BP)'},
        {'name': 'Focus Sash', 'location': 'Battle Park (48 BP)'},
      ],
    },
  };

  List<String> get _categories {
    final cats = <String>{'All'};
    final gameItems = _itemLocations[_selectedGame] ?? {};
    cats.addAll(gameItems.keys);
    return cats.toList();
  }

  List<Map<String, String>> get _filteredItems {
    final gameItems = _itemLocations[_selectedGame] ?? {};
    final items = <Map<String, String>>[];

    for (var entry in gameItems.entries) {
      if (_selectedCategory == 'All' || _selectedCategory == entry.key) {
        for (var item in entry.value) {
          if (_searchQuery.isEmpty ||
              item['name']!.toLowerCase().contains(_searchQuery.toLowerCase())) {
            items.add({...item, 'category': entry.key});
          }
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Locations'), backgroundColor: Colors.red),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedGame, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Game', border: OutlineInputBorder()),
              items: _itemLocations.keys.map((g) =>
                DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() { _selectedGame = v!; _selectedCategory = 'All'; }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _selectedCategory == c,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _categoryColor(item['category']!),
                      child: const Icon(Icons.backpack, color: Colors.white, size: 18),
                    ),
                    title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(item['location']!, style: const TextStyle(fontSize: 12)),
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

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Evolution': return Colors.purple;
      case 'Held': return Colors.blue;
      case 'EV Training': return Colors.teal;
      case 'Battle': return Colors.red;
      default: return Colors.grey;
    }
  }
}
