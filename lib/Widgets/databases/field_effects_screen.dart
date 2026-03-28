import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FieldEffectsScreen extends StatefulWidget {
  const FieldEffectsScreen({Key? key}) : super(key: key);

  @override
  State<FieldEffectsScreen> createState() => _FieldEffectsScreenState();
}

class _FieldEffectsScreenState extends State<FieldEffectsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: const Text('Field Effects'),
        backgroundColor: Colors.red,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hazards'),
            Tab(text: 'Weather'),
            Tab(text: 'Terrain'),
            Tab(text: 'Screens'),
            Tab(text: 'Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHazards(),
          _buildWeather(),
          _buildTerrain(),
          _buildScreens(),
          _buildStatus(),
        ],
      ),
    );
  }

  Widget _buildHazards() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _effectCard('Stealth Rock', 'Rock', [
          'Damages Pokemon switching in based on type effectiveness to Rock:',
          '  4x weak (Bug/Fire, etc.): 50% max HP',
          '  2x weak (Fire, Ice, etc.): 25% max HP',
          '  Neutral: 12.5% max HP',
          '  2x resist: 6.25% max HP',
          '  4x resist: 3.125% max HP',
          'Removed by: Rapid Spin, Defog, Court Change',
          'Blocked by: Magic Guard ability',
          'Only one layer needed',
        ]),
        _effectCard('Spikes', 'Ground', [
          'Damages grounded Pokemon switching in:',
          '  1 layer: 12.5% max HP',
          '  2 layers: 16.67% max HP',
          '  3 layers (max): 25% max HP',
          'Does NOT affect Flying types or Levitate',
          'Removed by: Rapid Spin, Defog, Court Change',
        ]),
        _effectCard('Toxic Spikes', 'Poison', [
          '1 layer: Poisons grounded Pokemon switching in',
          '2 layers: Badly poisons grounded Pokemon',
          'Does NOT affect Flying, Levitate, or Steel types',
          'Poison types absorb Toxic Spikes on entry (removes them)',
          'Removed by: Rapid Spin, Defog, Court Change, Poison-type entry',
        ]),
        _effectCard('Sticky Web', 'Bug', [
          'Lowers Speed by 1 stage on grounded switch-in',
          'Does NOT affect Flying types or Levitate',
          'Only one layer',
          'Removed by: Rapid Spin, Defog, Court Change',
          'Defiant/Competitive triggers on the Speed drop!',
        ]),
        _effectCard('Ceaseless Edge', 'Dark', [
          'Sets Spikes on the opponent\'s side on hit',
          'Signature move of Hisuian Samurott',
          'Functions as an attacking move + Spikes combined',
        ]),
        _effectCard('Stone Axe', 'Rock', [
          'Sets Stealth Rock on the opponent\'s side on hit',
          'Signature move of Kleavor',
        ]),
      ],
    );
  }

  Widget _buildWeather() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _effectCard('Sun (Harsh Sunlight)', 'Fire', [
          'Duration: 5 turns (8 with Heat Rock)',
          'Fire moves: 1.5x damage',
          'Water moves: 0.5x damage',
          'Solar Beam: No charge turn needed',
          'Thunder/Hurricane: 50% accuracy',
          'Moonlight/Synthesis/Morning Sun: Heals 66% HP',
          'Growth: +2 Atk and SpAtk instead of +1',
          'Activates: Chlorophyll (2x Speed), Solar Power (+50% SpAtk, -12.5% HP/turn)',
          'Abilities: Drought sets it, Protosynthesis activates',
        ]),
        _effectCard('Rain', 'Water', [
          'Duration: 5 turns (8 with Damp Rock)',
          'Water moves: 1.5x damage',
          'Fire moves: 0.5x damage',
          'Thunder/Hurricane: Never miss',
          'Solar Beam: 50% power',
          'Moonlight/Synthesis/Morning Sun: Heals 25% HP',
          'Activates: Swift Swim (2x Speed), Rain Dish (+6.25% HP/turn)',
          'Abilities: Drizzle sets it, Quark Drive activates',
        ]),
        _effectCard('Sandstorm', 'Rock', [
          'Duration: 5 turns (8 with Smooth Rock)',
          'Deals 6.25% max HP damage per turn to non-Rock/Ground/Steel',
          'Rock types: +50% Special Defense',
          'Activates: Sand Rush (2x Speed), Sand Force (+30% Rock/Ground/Steel moves)',
          'Blocked by: Magic Guard, Overcoat, Safety Goggles',
          'Abilities: Sand Stream sets it',
        ]),
        _effectCard('Snow (Hail)', 'Ice', [
          'Gen 9 (Snow): Ice types get +50% Defense',
          'Gen 1-8 (Hail): 6.25% damage/turn to non-Ice types',
          'Duration: 5 turns (8 with Icy Rock)',
          'Blizzard: Never misses in hail/snow',
          'Aurora Veil: Can only be used in hail/snow',
          'Activates: Slush Rush (2x Speed), Ice Face (reforms)',
          'Abilities: Snow Warning sets it',
        ]),
      ],
    );
  }

  Widget _buildTerrain() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _effectCard('Electric Terrain', 'Electric', [
          'Duration: 5 turns (8 with Terrain Extender)',
          'Grounded Pokemon: +30% Electric move damage',
          'Prevents Sleep on grounded Pokemon',
          'Rising Voltage: Doubles power (140 base)',
          'Set by: Electric Surge, Pincurchin, Tapu Koko',
        ]),
        _effectCard('Grassy Terrain', 'Grass', [
          'Duration: 5 turns (8 with Terrain Extender)',
          'Grounded Pokemon: +30% Grass move damage',
          'Grounded Pokemon: Heals 6.25% HP per turn',
          'Earthquake/Bulldoze/Magnitude: 50% power',
          'Grassy Glide: Priority in Grassy Terrain',
          'Set by: Grassy Surge, Rillaboom, Tapu Bulu',
        ]),
        _effectCard('Misty Terrain', 'Fairy', [
          'Duration: 5 turns (8 with Terrain Extender)',
          'Grounded Pokemon: Cannot be statused',
          'Dragon moves: 50% power on grounded targets',
          'Misty Explosion: Doubles power',
          'Set by: Misty Surge, Weezing-Galar, Tapu Fini',
          'Note: Airborne Pokemon are NOT protected!',
        ]),
        _effectCard('Psychic Terrain', 'Psychic', [
          'Duration: 5 turns (8 with Terrain Extender)',
          'Grounded Pokemon: +30% Psychic move damage',
          'Blocks priority moves against grounded Pokemon',
          'Expanding Force: Hits all opponents, +50% power',
          'Set by: Psychic Surge, Indeedee, Tapu Lele',
          'Note: Priority moves can still target airborne Pokemon!',
        ]),
      ],
    );
  }

  Widget _buildScreens() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _effectCard('Reflect', 'Psychic', [
          'Duration: 5 turns (8 with Light Clay)',
          'Halves physical damage taken by the team',
          'Singles: 50% damage reduction',
          'Doubles: 33% damage reduction',
          'Does NOT reduce critical hits',
          'Removed by: Brick Break, Psychic Fangs, Defog',
        ]),
        _effectCard('Light Screen', 'Psychic', [
          'Duration: 5 turns (8 with Light Clay)',
          'Halves special damage taken by the team',
          'Singles: 50% damage reduction',
          'Doubles: 33% damage reduction',
          'Does NOT reduce critical hits',
          'Removed by: Brick Break, Psychic Fangs, Defog',
        ]),
        _effectCard('Aurora Veil', 'Ice', [
          'Duration: 5 turns (8 with Light Clay)',
          'Halves ALL damage (physical AND special)',
          'Can only be used during Hail/Snow',
          'Stacks with neither Reflect nor Light Screen',
          'Removed by: Brick Break, Psychic Fangs, Defog',
        ]),
        _effectCard('Tailwind', 'Flying', [
          'Duration: 4 turns (including turn used)',
          'Doubles Speed of all team members',
          'Critical for VGC speed control',
          'Common users: Tornadus, Whimsicott, Talonflame',
        ]),
        _effectCard('Trick Room', 'Psychic', [
          'Duration: 5 turns (including turn used)',
          'Slower Pokemon move first',
          'Priority moves are unaffected',
          'Speed stat is effectively inverted',
          'Using Trick Room again ends it early',
          '-1 Priority move (always goes last in its bracket)',
        ]),
      ],
    );
  }

  Widget _buildStatus() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _effectCard('Burn', 'Fire', [
          'Damage: 6.25% max HP per turn (Gen 7+)',
          'Halves physical Attack stat',
          'Does NOT affect special attacks',
          'Immune: Fire types',
          'Cured by: Rawst Berry, Heal Bell, Aromatherapy, Lum Berry',
          'Guts: Attack boost instead of reduction',
          'Facade: Doubles power when burned',
        ]),
        _effectCard('Paralysis', 'Electric', [
          'Speed: Reduced to 50% (Gen 7+)',
          '25% chance of being fully paralyzed each turn',
          'Immune: Electric types (Gen 6+)',
          'Immune: Limber ability',
          'Cured by: Cheri Berry, Heal Bell, Lum Berry',
        ]),
        _effectCard('Poison', 'Poison', [
          'Regular Poison: 12.5% max HP per turn',
          'Bad Poison (Toxic): Starts at 6.25%, increases each turn',
          '  Turn 1: 6.25%, Turn 2: 12.5%, Turn 3: 18.75%...',
          'Immune: Poison and Steel types',
          'Poison Heal: Heals 12.5% instead of taking damage',
          'Toxic Orb: Badly poisons holder at end of turn 1',
        ]),
        _effectCard('Sleep', 'Normal', [
          'Duration: 1-3 turns (Gen 5+)',
          'Cannot use moves (except Sleep Talk, Snore)',
          'Wake up check happens at start of turn',
          'Early Bird: Halves sleep duration',
          'Rest: Sleeps for exactly 2 turns, full heal',
          'Gen 9: Dark Void accuracy lowered to 50% for non-Darkrai',
        ]),
        _effectCard('Freeze', 'Ice', [
          'Cannot use moves',
          '20% chance of thawing each turn',
          'Guaranteed thaw: Fire moves, Scald, Steam Eruption',
          'Using Flame Wheel, Sacred Fire, etc. thaws user',
          'Immune: Ice types (Gen 7+)',
          'Extremely rare status in competitive play',
        ]),
        _effectCard('Confusion', 'Normal', [
          'Duration: 1-4 turns',
          '33% chance of hitting self each turn (Gen 7+)',
          'Self-hit: 40 power physical move against self',
          'Not a true "status condition" - can overlap with others',
          'Own Tempo: Immune to confusion',
          'Cured by: Persim Berry, switching out',
        ]),
      ],
    );
  }

  Widget _effectCard(String name, String type, List<String> details) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.typeColors[type] ?? Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: d.isEmpty
                  ? const SizedBox(height: 4)
                  : Text(d, style: TextStyle(
                      fontSize: 13,
                      color: d.startsWith('  ') ? Colors.blue.shade700 : null,
                    )),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
