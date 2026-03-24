import 'package:flutter/material.dart';
import '../tools/damage_calculator_screen.dart';
import '../tools/weakness_analyzer_screen.dart';
import '../tools/compare_pokemon_screen.dart';
import '../tools/speed_tier_screen.dart';
import '../tools/breeding_helper_screen.dart';
import '../pokemon/learnset_screen.dart';
import '../pokemon/regional_forms_screen.dart';
import '../pokemon/competitive_sets_screen.dart';

class ToolsHub extends StatelessWidget {
  const ToolsHub({Key? key}) : super(key: key);

  static const _items = [
    {'title': 'Damage Calculator', 'subtitle': 'Calculate move damage', 'icon': Icons.calculate, 'color': Colors.red},
    {'title': 'Weakness Analyzer', 'subtitle': 'Team coverage analysis', 'icon': Icons.shield, 'color': Colors.blue},
    {'title': 'Compare Pokemon', 'subtitle': 'Side-by-side stats', 'icon': Icons.compare_arrows, 'color': Colors.green},
    {'title': 'Speed Tiers', 'subtitle': 'Speed stat rankings', 'icon': Icons.speed, 'color': Colors.orange},
    {'title': 'Breeding Helper', 'subtitle': 'Egg group checker', 'icon': Icons.egg, 'color': Colors.pink},
    {'title': 'Learnsets', 'subtitle': 'Moves by Pokemon', 'icon': Icons.school, 'color': Colors.purple},
    {'title': 'Regional Forms', 'subtitle': 'Alolan, Galarian, etc.', 'icon': Icons.public, 'color': Colors.teal},
    {'title': 'Competitive Sets', 'subtitle': 'Smogon-style builds', 'icon': Icons.emoji_events, 'color': Colors.amber},
  ];

  void _navigate(BuildContext context, int index) {
    final screens = [
      const DamageCalculatorScreen(),
      const WeaknessAnalyzerScreen(),
      const ComparePokemonScreen(),
      const SpeedTierScreen(),
      const BreedingHelperScreen(),
      const LearnsetScreen(),
      const RegionalFormsScreen(),
      const CompetitiveSetsScreen(),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (_) => screens[index]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools'), backgroundColor: Colors.red),
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
              subtitle: Text(item['subtitle'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(context, index),
            ),
          );
        },
      ),
    );
  }
}
