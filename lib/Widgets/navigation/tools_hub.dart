import 'package:flutter/material.dart';
import '../tools/damage_calculator_screen.dart';
import '../tools/weakness_analyzer_screen.dart';
import '../tools/compare_pokemon_screen.dart';
import '../tools/speed_tier_screen.dart';
import '../tools/breeding_helper_screen.dart';
import '../tools/breeding_chain_screen.dart';
import '../tools/catch_calculator_screen.dart';
import '../tools/evolution_methods_screen.dart';
import '../tools/reverse_move_lookup_screen.dart';
import '../tools/reverse_ability_lookup_screen.dart';
import '../tools/shiny_calculator_screen.dart';
import '../tools/stat_ranker_screen.dart';
import '../tools/xp_calculator_screen.dart';
import '../tools/usage_stats_screen.dart';
import '../pokemon/learnset_screen.dart';
import '../pokemon/regional_forms_screen.dart';
import '../pokemon/competitive_sets_screen.dart';

class ToolsHub extends StatelessWidget {
  const ToolsHub({Key? key}) : super(key: key);

  static const _items = [
    {'title': 'Damage Calculator', 'subtitle': 'Calculate move damage', 'icon': Icons.calculate, 'color': Colors.red},
    {'title': 'Catch Calculator', 'subtitle': 'Catch rate & ball odds', 'icon': Icons.sports_baseball, 'color': Colors.green},
    {'title': 'Weakness Analyzer', 'subtitle': 'Team coverage analysis', 'icon': Icons.shield, 'color': Colors.blue},
    {'title': 'Compare Pokemon', 'subtitle': 'Side-by-side stats', 'icon': Icons.compare_arrows, 'color': Colors.indigo},
    {'title': 'Speed Tiers', 'subtitle': 'Speed stat rankings', 'icon': Icons.speed, 'color': Colors.orange},
    {'title': 'Stat Ranker', 'subtitle': 'Filter & rank by stats', 'icon': Icons.leaderboard, 'color': Colors.deepPurple},
    {'title': 'Evolution Methods', 'subtitle': 'How to evolve per game', 'icon': Icons.transform, 'color': Colors.teal},
    {'title': 'Move → Pokemon', 'subtitle': 'Who learns this move?', 'icon': Icons.swap_horiz, 'color': Colors.cyan},
    {'title': 'Ability → Pokemon', 'subtitle': 'Who has this ability?', 'icon': Icons.swap_vert, 'color': Colors.lime},
    {'title': 'Breeding Helper', 'subtitle': 'Egg group checker', 'icon': Icons.egg, 'color': Colors.pink},
    {'title': 'Breeding Chains', 'subtitle': 'Egg move parents finder', 'icon': Icons.account_tree, 'color': Colors.pinkAccent},
    {'title': 'Shiny Calculator', 'subtitle': 'Shiny odds per method', 'icon': Icons.star, 'color': Colors.amber},
    {'title': 'XP Calculator', 'subtitle': 'Level-up experience', 'icon': Icons.trending_up, 'color': Colors.lightBlue},
    {'title': 'Usage Stats', 'subtitle': 'Smogon tier rankings', 'icon': Icons.bar_chart, 'color': Colors.brown},
    {'title': 'Learnsets', 'subtitle': 'Moves by Pokemon', 'icon': Icons.school, 'color': Colors.purple},
    {'title': 'Regional Forms', 'subtitle': 'Alolan, Galarian, etc.', 'icon': Icons.public, 'color': Colors.blueGrey},
    {'title': 'Competitive Sets', 'subtitle': 'Smogon-style builds', 'icon': Icons.emoji_events, 'color': Colors.deepOrange},
  ];

  void _navigate(BuildContext context, int index) {
    final screens = [
      const DamageCalculatorScreen(),
      const CatchCalculatorScreen(),
      const WeaknessAnalyzerScreen(),
      const ComparePokemonScreen(),
      const SpeedTierScreen(),
      const StatRankerScreen(),
      const EvolutionMethodsScreen(),
      const ReverseMoveLookupScreen(),
      const ReverseAbilityLookupScreen(),
      const BreedingHelperScreen(),
      const BreedingChainScreen(),
      const ShinyCalculatorScreen(),
      const XPCalculatorScreen(),
      const UsageStatsScreen(),
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
