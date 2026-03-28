import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';

class UsageStatsScreen extends StatefulWidget {
  const UsageStatsScreen({Key? key}) : super(key: key);

  @override
  State<UsageStatsScreen> createState() => _UsageStatsScreenState();
}

class _UsageStatsScreenState extends State<UsageStatsScreen> {
  String _selectedTier = 'OU';

  // Curated competitive tier data (Smogon Gen 9 approximation)
  static const Map<String, List<Map<String, dynamic>>> _tierData = {
    'OU': [
      {'name': 'Great Tusk', 'usage': 28.5, 'role': 'Hazard Lead / Spinner'},
      {'name': 'Gholdengo', 'usage': 26.1, 'role': 'Special Attacker / Hazard Blocker'},
      {'name': 'Kingambit', 'usage': 24.8, 'role': 'Wincon / Sucker Punch'},
      {'name': 'Dragapult', 'usage': 22.3, 'role': 'Fast Attacker / Hex'},
      {'name': 'Iron Valiant', 'usage': 20.1, 'role': 'Mixed Attacker'},
      {'name': 'Gliscor', 'usage': 19.7, 'role': 'Defensive Pivot / Toxic'},
      {'name': 'Heatran', 'usage': 18.9, 'role': 'Special Wall / Trapper'},
      {'name': 'Landorus-Therian', 'usage': 18.2, 'role': 'Pivot / Stealth Rock'},
      {'name': 'Corviknight', 'usage': 17.5, 'role': 'Physical Wall / Defog'},
      {'name': 'Darkrai', 'usage': 16.8, 'role': 'Special Sweeper / Dark Void'},
      {'name': 'Samurott-Hisui', 'usage': 15.3, 'role': 'Ceaseless Edge Spam'},
      {'name': 'Clefable', 'usage': 14.9, 'role': 'Special Wall / Wish'},
      {'name': 'Toxapex', 'usage': 14.2, 'role': 'Physical Wall / Toxic'},
      {'name': 'Iron Moth', 'usage': 13.7, 'role': 'Special Attacker'},
      {'name': 'Roaring Moon', 'usage': 13.1, 'role': 'Dragon Dance Sweeper'},
      {'name': 'Skeledirge', 'usage': 12.8, 'role': 'Bulky Special Attacker'},
      {'name': 'Zamazenta', 'usage': 12.3, 'role': 'Physical Wall'},
      {'name': 'Slowking-Galar', 'usage': 11.9, 'role': 'Regenerator Pivot'},
      {'name': 'Garganacl', 'usage': 11.4, 'role': 'Salt Cure Tank'},
      {'name': 'Volcarona', 'usage': 10.8, 'role': 'Quiver Dance Sweeper'},
    ],
    'UU': [
      {'name': 'Hydreigon', 'usage': 22.1, 'role': 'Special Attacker'},
      {'name': 'Bisharp', 'usage': 20.5, 'role': 'Physical Sweeper / Defiant'},
      {'name': 'Scizor', 'usage': 19.8, 'role': 'Priority Attacker / Pivot'},
      {'name': 'Primarina', 'usage': 18.3, 'role': 'Special Attacker / Wall'},
      {'name': 'Infernape', 'usage': 17.1, 'role': 'Mixed Attacker'},
      {'name': 'Salamence', 'usage': 16.4, 'role': 'Dragon Dance / Special'},
      {'name': 'Tentacruel', 'usage': 15.7, 'role': 'Hazard Removal / Pivot'},
      {'name': 'Mimikyu', 'usage': 15.2, 'role': 'Swords Dance Sweeper'},
      {'name': 'Rotom-Wash', 'usage': 14.6, 'role': 'Defensive Pivot'},
      {'name': 'Lucario', 'usage': 14.1, 'role': 'Physical / Special Sweeper'},
    ],
    'Uber': [
      {'name': 'Koraidon', 'usage': 45.2, 'role': 'Physical Sweeper / Sun'},
      {'name': 'Miraidon', 'usage': 43.8, 'role': 'Special Sweeper / Electric Terrain'},
      {'name': 'Calyrex-Shadow', 'usage': 35.1, 'role': 'Special Sweeper'},
      {'name': 'Zacian-Crowned', 'usage': 32.7, 'role': 'Physical Sweeper'},
      {'name': 'Arceus', 'usage': 28.4, 'role': 'Support / Various Types'},
      {'name': 'Kyogre', 'usage': 25.9, 'role': 'Rain Special Attacker'},
      {'name': 'Ho-Oh', 'usage': 22.3, 'role': 'Physical Wall / Regenerator'},
      {'name': 'Giratina-Origin', 'usage': 20.8, 'role': 'Defog / Spinblocker'},
      {'name': 'Necrozma-Dusk Mane', 'usage': 19.5, 'role': 'Physical Tank / Stealth Rock'},
      {'name': 'Groudon', 'usage': 18.1, 'role': 'Sun Support / Physical'},
    ],
    'VGC': [
      {'name': 'Flutter Mane', 'usage': 35.6, 'role': 'Special Attacker'},
      {'name': 'Incineroar', 'usage': 33.2, 'role': 'Intimidate Support'},
      {'name': 'Rillaboom', 'usage': 28.9, 'role': 'Grassy Terrain / Fake Out'},
      {'name': 'Amoonguss', 'usage': 26.4, 'role': 'Spore / Redirector'},
      {'name': 'Urshifu-Rapid', 'usage': 24.7, 'role': 'Physical Sweeper'},
      {'name': 'Tornadus', 'usage': 22.1, 'role': 'Tailwind Support'},
      {'name': 'Chien-Pao', 'usage': 20.5, 'role': 'Physical Sweeper / Sword of Ruin'},
      {'name': 'Landorus', 'usage': 19.8, 'role': 'Special Attacker / Intimidate'},
      {'name': 'Iron Hands', 'usage': 18.3, 'role': 'Fake Out / Bulk'},
      {'name': 'Ogerpon-Wellspring', 'usage': 17.6, 'role': 'Water Tera / Attacker'},
    ],
  };

  static const List<String> _tiers = ['Uber', 'OU', 'UU', 'VGC'];

  @override
  Widget build(BuildContext context) {
    final tierPokemon = _tierData[_selectedTier] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Usage Stats & Tiers'), backgroundColor: Colors.red),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _tiers.map((tier) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(tier),
                    selected: _selectedTier == tier,
                    onSelected: (v) => setState(() => _selectedTier = tier),
                  ),
                ),
              )).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('$_selectedTier Tier', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                const Text('Gen 9 (approximate)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: tierPokemon.length,
              itemBuilder: (context, index) {
                final pokemon = tierPokemon[index];
                final usage = pokemon['usage'] as double;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _usageColor(usage),
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(pokemon['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(pokemon['role'], style: const TextStyle(fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${usage.toStringAsFixed(1)}%',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _usageColor(usage))),
                        const Text('usage', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Data is approximate. For live stats, visit smogon.com/stats',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Color _usageColor(double usage) {
    if (usage >= 30) return Colors.red;
    if (usage >= 20) return Colors.orange;
    if (usage >= 15) return Colors.amber.shade700;
    return Colors.blue;
  }
}
