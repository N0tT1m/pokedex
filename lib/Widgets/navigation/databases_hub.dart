import 'package:flutter/material.dart';
import '../databases/type_chart_screen.dart';
import '../databases/nature_chart_screen.dart';
import '../databases/move_database_screen.dart';
import '../databases/ability_database_screen.dart';
import '../databases/item_database_screen.dart';
import '../databases/item_location_screen.dart';
import '../databases/location_guide_screen.dart';
import '../databases/battle_mechanics_screen.dart';
import '../databases/field_effects_screen.dart';
import '../databases/legendary_pokemon_screen.dart';
import '../databases/grand_underground_screen.dart';
import '../databases/tm_finder_screen.dart';
import '../databases/berry_guide_screen.dart';
import '../databases/friendship_reference_screen.dart';

class DatabasesHub extends StatelessWidget {
  const DatabasesHub({Key? key}) : super(key: key);

  static const _items = [
    {'title': 'Type Chart', 'icon': Icons.grid_on, 'color': Colors.orange},
    {'title': 'Natures', 'icon': Icons.nature, 'color': Colors.green},
    {'title': 'Moves', 'icon': Icons.flash_on, 'color': Colors.blue},
    {'title': 'Abilities', 'icon': Icons.auto_awesome, 'color': Colors.purple},
    {'title': 'Items', 'icon': Icons.backpack, 'color': Colors.teal},
    {'title': 'Item Locations', 'icon': Icons.location_on, 'color': Colors.deepOrange},
    {'title': 'TM / HM Finder', 'icon': Icons.disc_full, 'color': Colors.indigo},
    {'title': 'Berry Guide', 'icon': Icons.eco, 'color': Colors.lightGreen},
    {'title': 'Locations', 'icon': Icons.map, 'color': Colors.brown},
    {'title': 'Battle Mechanics', 'icon': Icons.sports_mma, 'color': Colors.red},
    {'title': 'Field Effects', 'icon': Icons.landscape, 'color': Colors.cyan},
    {'title': 'Friendship & Pokerus', 'icon': Icons.favorite, 'color': Colors.pink},
    {'title': 'Legendary Pokemon', 'icon': Icons.star, 'color': Colors.blueAccent},
    {'title': 'Grand Underground', 'icon': Icons.layers, 'color': Colors.blueGrey},
  ];

  void _navigate(BuildContext context, int index) {
    final screens = [
      const TypeChartScreen(),
      const NatureChartScreen(),
      const MoveDatabaseScreen(),
      const AbilityDatabaseScreen(),
      const ItemDatabaseScreen(),
      const ItemLocationScreen(),
      const TMFinderScreen(),
      const BerryGuideScreen(),
      const LocationGuideScreen(),
      const BattleMechanicsScreen(),
      const FieldEffectsScreen(),
      const FriendshipReferenceScreen(),
      const LegendaryPokemonScreen(),
      const GrandUndergroundScreen(),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (_) => screens[index]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database'), backgroundColor: Colors.red),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item['color'] as Color,
                child: Icon(item['icon'] as IconData, color: Colors.white),
              ),
              title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(context, index),
            ),
          );
        },
      ),
    );
  }
}
