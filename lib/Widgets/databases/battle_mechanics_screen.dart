import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BattleMechanicsScreen extends StatelessWidget {
  const BattleMechanicsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battle Mechanics'),
          backgroundColor: Colors.red,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(text: 'Mega Evolution'),
              Tab(text: 'Z-Moves'),
              Tab(text: 'Dynamax'),
              Tab(text: 'Terastallize'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MegaEvolutionTab(),
            _ZMoveTab(),
            _DynamaxTab(),
            _TerastallizeTab(),
          ],
        ),
      ),
    );
  }
}

class _MegaEvolutionTab extends StatelessWidget {
  const _MegaEvolutionTab();

  static const _megaEvolutions = [
    {'pokemon': 'Venusaur', 'type': 'Grass, Poison', 'ability': 'Thick Fat', 'stone': 'Venusaurite'},
    {'pokemon': 'Charizard X', 'type': 'Fire, Dragon', 'ability': 'Tough Claws', 'stone': 'Charizardite X'},
    {'pokemon': 'Charizard Y', 'type': 'Fire, Flying', 'ability': 'Drought', 'stone': 'Charizardite Y'},
    {'pokemon': 'Blastoise', 'type': 'Water', 'ability': 'Mega Launcher', 'stone': 'Blastoisinite'},
    {'pokemon': 'Alakazam', 'type': 'Psychic', 'ability': 'Trace', 'stone': 'Alakazite'},
    {'pokemon': 'Gengar', 'type': 'Ghost, Poison', 'ability': 'Shadow Tag', 'stone': 'Gengarite'},
    {'pokemon': 'Kangaskhan', 'type': 'Normal', 'ability': 'Parental Bond', 'stone': 'Kangaskhanite'},
    {'pokemon': 'Pinsir', 'type': 'Bug, Flying', 'ability': 'Aerilate', 'stone': 'Pinsirite'},
    {'pokemon': 'Gyarados', 'type': 'Water, Dark', 'ability': 'Mold Breaker', 'stone': 'Gyaradosite'},
    {'pokemon': 'Scizor', 'type': 'Bug, Steel', 'ability': 'Technician', 'stone': 'Scizorite'},
    {'pokemon': 'Tyranitar', 'type': 'Rock, Dark', 'ability': 'Sand Stream', 'stone': 'Tyranitarite'},
    {'pokemon': 'Blaziken', 'type': 'Fire, Fighting', 'ability': 'Speed Boost', 'stone': 'Blazikenite'},
    {'pokemon': 'Gardevoir', 'type': 'Psychic, Fairy', 'ability': 'Pixilate', 'stone': 'Gardevoirite'},
    {'pokemon': 'Mawile', 'type': 'Steel, Fairy', 'ability': 'Huge Power', 'stone': 'Mawilite'},
    {'pokemon': 'Aggron', 'type': 'Steel', 'ability': 'Filter', 'stone': 'Aggronite'},
    {'pokemon': 'Medicham', 'type': 'Fighting, Psychic', 'ability': 'Pure Power', 'stone': 'Medichamite'},
    {'pokemon': 'Manectric', 'type': 'Electric', 'ability': 'Intimidate', 'stone': 'Manectite'},
    {'pokemon': 'Garchomp', 'type': 'Dragon, Ground', 'ability': 'Sand Force', 'stone': 'Garchompite'},
    {'pokemon': 'Lucario', 'type': 'Fighting, Steel', 'ability': 'Adaptability', 'stone': 'Lucarionite'},
    {'pokemon': 'Metagross', 'type': 'Steel, Psychic', 'ability': 'Tough Claws', 'stone': 'Metagrossite'},
    {'pokemon': 'Rayquaza', 'type': 'Dragon, Flying', 'ability': 'Delta Stream', 'stone': 'Dragon Ascent'},
    {'pokemon': 'Lopunny', 'type': 'Normal, Fighting', 'ability': 'Scrappy', 'stone': 'Lopunnite'},
    {'pokemon': 'Salamence', 'type': 'Dragon, Flying', 'ability': 'Aerilate', 'stone': 'Salamencite'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _megaEvolutions.length,
      itemBuilder: (context, index) {
        final mega = _megaEvolutions[index];
        return Card(
          child: ListTile(
            title: Text('Mega ${mega['pokemon']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${mega['type']}'),
                Text('Ability: ${mega['ability']}'),
                Text('Item: ${mega['stone']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZMoveTab extends StatelessWidget {
  const _ZMoveTab();

  static const _zMoves = [
    {'type': 'Normal', 'name': 'Breakneck Blitz', 'power': '100-200'},
    {'type': 'Fire', 'name': 'Inferno Overdrive', 'power': '100-200'},
    {'type': 'Water', 'name': 'Hydro Vortex', 'power': '100-200'},
    {'type': 'Electric', 'name': 'Gigavolt Havoc', 'power': '100-200'},
    {'type': 'Grass', 'name': 'Bloom Doom', 'power': '100-200'},
    {'type': 'Ice', 'name': 'Subzero Slammer', 'power': '100-200'},
    {'type': 'Fighting', 'name': 'All-Out Pummeling', 'power': '100-200'},
    {'type': 'Poison', 'name': 'Acid Downpour', 'power': '100-200'},
    {'type': 'Ground', 'name': 'Tectonic Rage', 'power': '100-200'},
    {'type': 'Flying', 'name': 'Supersonic Skystrike', 'power': '100-200'},
    {'type': 'Psychic', 'name': 'Shattered Psyche', 'power': '100-200'},
    {'type': 'Bug', 'name': 'Savage Spin-Out', 'power': '100-200'},
    {'type': 'Rock', 'name': 'Continental Crush', 'power': '100-200'},
    {'type': 'Ghost', 'name': 'Never-Ending Nightmare', 'power': '100-200'},
    {'type': 'Dragon', 'name': 'Devastating Drake', 'power': '100-200'},
    {'type': 'Dark', 'name': 'Black Hole Eclipse', 'power': '100-200'},
    {'type': 'Steel', 'name': 'Corkscrew Crash', 'power': '100-200'},
    {'type': 'Fairy', 'name': 'Twinkle Tackle', 'power': '100-200'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Z-Moves are powered-up moves from Gen VII (Sun/Moon).\n'
              'Requires a Z-Crystal matching the move type.\nPower scales with base move power.',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ),
        ..._zMoves.map((z) => Card(
          child: ListTile(
            leading: Container(
              width: 40, height: 40, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.typeColors[z['type']], borderRadius: BorderRadius.circular(8)),
              child: Text(z['type']!.substring(0, 3),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            title: Text(z['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Power: ${z['power']}'),
          ),
        )),
      ],
    );
  }
}

class _DynamaxTab extends StatelessWidget {
  const _DynamaxTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dynamax', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 8),
                  Text('Available in Sword & Shield only.\n\n'
                      '- Pokemon grows giant for 3 turns\n'
                      '- HP doubles\n'
                      '- All moves become Max Moves\n'
                      '- Max Moves have secondary effects\n'
                      '- Can only be used once per battle'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Gigantamax Pokemon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ..._gigantamaxPokemon.map((p) => Card(
            child: ListTile(
              title: Text(p['pokemon']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('G-Max Move: ${p['move']} (${p['type']})'),
            ),
          )),
        ],
      ),
    );
  }

  static const _gigantamaxPokemon = [
    {'pokemon': 'Charizard', 'move': 'G-Max Wildfire', 'type': 'Fire'},
    {'pokemon': 'Butterfree', 'move': 'G-Max Befuddle', 'type': 'Bug'},
    {'pokemon': 'Pikachu', 'move': 'G-Max Volt Crash', 'type': 'Electric'},
    {'pokemon': 'Meowth', 'move': 'G-Max Gold Rush', 'type': 'Normal'},
    {'pokemon': 'Machamp', 'move': 'G-Max Chi Strike', 'type': 'Fighting'},
    {'pokemon': 'Gengar', 'move': 'G-Max Terror', 'type': 'Ghost'},
    {'pokemon': 'Kingler', 'move': 'G-Max Foam Burst', 'type': 'Water'},
    {'pokemon': 'Lapras', 'move': 'G-Max Resonance', 'type': 'Ice'},
    {'pokemon': 'Eevee', 'move': 'G-Max Cuddle', 'type': 'Normal'},
    {'pokemon': 'Snorlax', 'move': 'G-Max Replenish', 'type': 'Normal'},
    {'pokemon': 'Garbodor', 'move': 'G-Max Malodor', 'type': 'Poison'},
    {'pokemon': 'Corviknight', 'move': 'G-Max Wind Rage', 'type': 'Flying'},
    {'pokemon': 'Orbeetle', 'move': 'G-Max Gravitas', 'type': 'Psychic'},
    {'pokemon': 'Drednaw', 'move': 'G-Max Stonesurge', 'type': 'Water'},
    {'pokemon': 'Coalossal', 'move': 'G-Max Volcalith', 'type': 'Rock'},
    {'pokemon': 'Sandaconda', 'move': 'G-Max Sandblast', 'type': 'Ground'},
    {'pokemon': 'Centiskorch', 'move': 'G-Max Centiferno', 'type': 'Fire'},
    {'pokemon': 'Hatterene', 'move': 'G-Max Smite', 'type': 'Fairy'},
    {'pokemon': 'Grimmsnarl', 'move': 'G-Max Snooze', 'type': 'Dark'},
    {'pokemon': 'Alcremie', 'move': 'G-Max Finale', 'type': 'Fairy'},
    {'pokemon': 'Copperajah', 'move': 'G-Max Steelsurge', 'type': 'Steel'},
    {'pokemon': 'Duraludon', 'move': 'G-Max Depletion', 'type': 'Dragon'},
    {'pokemon': 'Urshifu', 'move': 'G-Max One/Rapid Blow', 'type': 'Fighting'},
  ];
}

class _TerastallizeTab extends StatelessWidget {
  const _TerastallizeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Terastallize', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 8),
                  Text('Available in Scarlet & Violet.\n\n'
                      '- Changes Pokemon to its Tera Type\n'
                      '- STAB becomes 2x if Tera Type matches original type\n'
                      '- New STAB of 1.5x for non-matching Tera Type\n'
                      '- Lasts for the rest of battle\n'
                      '- Can only be used once per battle\n'
                      '- Recharges at Pokemon Center'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('All 18 Tera Types Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppTheme.typeColors.entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: e.value,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STAB Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Same Tera + Original type: 2.0x'),
                  Text('Same Tera + Not original: 1.5x'),
                  Text('Different Tera + Original type: 1.5x'),
                  Text('No match: 1.0x'),
                  SizedBox(height: 8),
                  Text('Stellar Tera Type: 2.0x STAB once per type, then 1.0x',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
