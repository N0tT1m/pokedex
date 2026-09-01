import 'package:flutter/material.dart';

class FriendshipReferenceScreen extends StatelessWidget {
  const FriendshipReferenceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friendship & Pokerus'), backgroundColor: Colors.red),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _section('Friendship Overview', [
            'Base friendship for most Pokemon: 50 (0-255 range)',
            'Friendship evolution threshold: 220+ (Gen 1-7) / 160+ (Gen 8+)',
            'Friendship affects Return/Frustration damage',
            'Max friendship (255) = Return at 102 power',
          ]),
          _section('Raising Friendship', [
            'Walking: +1 every 128 steps (50% chance)',
            'Leveling up: +3-5 depending on current friendship',
            'Using vitamins (Protein, Iron, etc.): +1-5',
            'EV-reducing berries: +10 (Gen 8+)',
            'Soothe Bell: Doubles friendship gains from most sources',
            'Luxury Ball: Doubles friendship gains',
            'Massage / Grooming: +30 (once per day)',
            'Camping/Picnic: +1-3 based on interaction',
            'Friendship berries: Use Pomeg, Kelpsy, etc.',
          ]),
          _section('Lowering Friendship', [
            'Fainting: -1 (Gen 6+)',
            'Using bitter medicine (Energy Root, etc.): -5 to -10',
            'Trading resets friendship to base value',
          ]),
          _section('Friendship Checker Locations', [
            'Gen 4 (DPPT/HGSS): Poketch app / Goldenrod City',
            'Gen 5 (BW/B2W2): Castelia City (rating lady)',
            'Gen 6 (XY/ORAS): Laverre City / Verdanturf Town',
            'Gen 7 (SM/USUM): Konikoni City',
            'Gen 8 (SwSh): Hammerlocke (friendship checker NPC)',
            'Gen 8 (BDSP): Poketch Friendship Checker app',
            'Gen 9 (SV): Cascarrafa (friendship checker NPC)',
          ]),
          const Divider(height: 32),
          _buildTitle('Pokerus'),
          _section('What is Pokerus?', [
            'A rare "virus" that doubles EV gains',
            'Chance of contracting: 1/21,845 per battle',
            'Rarer than a shiny Pokemon!',
            'Spreads to adjacent party members after battle',
            'Active for 1-4 days, then becomes cured (permanent 2x EVs)',
          ]),
          _section('Pokerus + Power Items', [
            'Base EV gain from battle: X',
            'With Pokerus: 2X',
            'With Power Item: X + 8',
            'With Pokerus + Power Item: 2(X + 8) = 2X + 16',
            '',
            'Example: Defeating a Zubat (1 Speed EV):',
            '  Normal: 1 Speed EV',
            '  Power Anklet: 1 + 8 = 9 Speed EVs',
            '  Pokerus: 2 × 1 = 2 Speed EVs',
            '  Pokerus + Power Anklet: 2 × (1 + 8) = 18 Speed EVs',
          ]),
          _section('Preserving Pokerus', [
            'Store infected Pokemon in PC before midnight',
            'Pokerus timer only ticks when Pokemon is in party',
            'Once cured (smiley face icon), it no longer spreads',
            'Cured Pokemon still get the 2x EV bonus permanently',
          ]),
          const Divider(height: 32),
          _buildTitle('EV Training Multipliers Reference'),
          _section('EV Gain Modifiers', [
            'Base EV gain: As listed per Pokemon',
            'Macho Brace: 2x all EVs (halves Speed in battle)',
            'Power Weight/Bracer/etc.: +8 EVs in specific stat',
            'Pokerus: 2x total EVs earned',
            'SOS Chaining (Gen 7): 2x EVs after first ally call',
          ]),
          _section('EV Limits', [
            'Maximum EVs per stat: 252',
            'Maximum total EVs: 510',
            'Common spread: 252/252/4 (two stats maxed)',
            'Each 4 EVs = 1 stat point at level 100',
          ]),
          _section('Quick EV Training (Gen 9)', [
            'Best method: Power Item + auto-battle groups',
            'No Pokerus in SV, but Power Items give +8',
            'With Power Item: 9 EVs per 1-EV Pokemon',
            'Need ~28 KOs to max a stat (252 EVs)',
            'Vitamins now uncapped: can use 26 of each to max',
          ]),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _section(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: item.isEmpty
                ? const SizedBox(height: 4)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!item.startsWith('  ')) const Text('• ', style: TextStyle(color: Colors.grey)),
                      Expanded(child: Text(item, style: TextStyle(
                        fontSize: 13,
                        color: item.startsWith('  ') ? Colors.blue.shade700 : null,
                        fontFamily: item.startsWith('  ') ? 'monospace' : null,
                      ))),
                    ],
                  ),
            )),
          ],
        ),
      ),
    );
  }
}
