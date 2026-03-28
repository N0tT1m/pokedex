import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({Key? key}) : super(key: key);

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  String _selectedGame = 'Scarlet / Violet';
  Set<String> _completed = {};
  late Box _box;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    _box = await Hive.openBox('walkthrough_progress');
    final saved = _box.get(_selectedGame, defaultValue: <String>[]);
    setState(() {
      _completed = Set<String>.from(List<String>.from(saved));
      _initialized = true;
    });
  }

  Future<void> _toggleStep(String step) async {
    setState(() {
      if (_completed.contains(step)) {
        _completed.remove(step);
      } else {
        _completed.add(step);
      }
    });
    await _box.put(_selectedGame, _completed.toList());
  }

  static const Map<String, List<Map<String, dynamic>>> _walkthroughs = {
    'Scarlet / Violet': [
      {'section': 'Getting Started', 'steps': [
        {'id': 'sv1', 'text': 'Choose starter: Sprigatito / Fuecoco / Quaxly', 'pokemon': 'Sprigatito, Fuecoco, Quaxly'},
        {'id': 'sv2', 'text': 'Catch early Pokemon on routes around Mesagoza', 'pokemon': 'Lechonk, Tarountula, Pawmi, Fletchling, Hoppip'},
        {'id': 'sv3', 'text': 'Visit Mesagoza - explore shops and school'},
      ]},
      {'section': 'Victory Road (Gyms)', 'steps': [
        {'id': 'sv_g1', 'text': 'Cortondo Gym - Bug (Lv 14-15)', 'pokemon': 'Nymble, Tarountula, Teddiursa (nearby)'},
        {'id': 'sv_g2', 'text': 'Artazon Gym - Grass (Lv 16-17)', 'pokemon': 'Smoliv, Petilil, Sudowoodo (nearby)'},
        {'id': 'sv_g3', 'text': 'Levincia Gym - Electric (Lv 23-24)', 'pokemon': 'Luxio, Pachirisu, Flaaffy (nearby)'},
        {'id': 'sv_g4', 'text': 'Cascarrafa Gym - Water (Lv 29-30)', 'pokemon': 'Veluza, Dondozo, Crabrawler (nearby)'},
        {'id': 'sv_g5', 'text': 'Medali Gym - Normal (Lv 35-36)', 'pokemon': 'Dunsparce, Zangoose, Seviper (nearby)'},
        {'id': 'sv_g6', 'text': 'Montenevera Gym - Ghost (Lv 41-42)', 'pokemon': 'Greavard, Snom, Snover (nearby)'},
        {'id': 'sv_g7', 'text': 'Alfornada Gym - Psychic (Lv 44-45)', 'pokemon': 'Flittle, Gothita, Duosion (nearby)'},
        {'id': 'sv_g8', 'text': 'Glaseado Gym - Ice (Lv 47-48)', 'pokemon': 'Cetoddle, Beartic, Cryogonal (nearby)'},
      ]},
      {'section': 'Path of Legends (Titans)', 'steps': [
        {'id': 'sv_t1', 'text': 'Stony Cliff Titan - Klawf (Lv 16)', 'pokemon': 'Nacli, Rockruff'},
        {'id': 'sv_t2', 'text': 'Open Sky Titan - Bombirdier (Lv 20)', 'pokemon': 'Squawkabilly, Flamigo'},
        {'id': 'sv_t3', 'text': 'Lurking Steel Titan - Orthworm (Lv 29)', 'pokemon': 'Varoom, Tinkatink'},
        {'id': 'sv_t4', 'text': 'Quaking Earth Titan - Great Tusk/Iron Treads (Lv 45)', 'pokemon': 'Phanpy/Magnemite'},
        {'id': 'sv_t5', 'text': 'False Dragon Titan - Dondozo/Tatsugiri (Lv 56)', 'pokemon': 'Dratini, Dragonair'},
      ]},
      {'section': 'Starfall Street (Team Star)', 'steps': [
        {'id': 'sv_s1', 'text': 'Dark Crew - Giacomo (Lv 21)', 'pokemon': 'Murkrow, Stunky'},
        {'id': 'sv_s2', 'text': 'Fire Crew - Mela (Lv 27)', 'pokemon': 'Litleo, Houndour'},
        {'id': 'sv_s3', 'text': 'Poison Crew - Atticus (Lv 33)', 'pokemon': 'Foongus, Croagunk, Gulpin'},
        {'id': 'sv_s4', 'text': 'Fairy Crew - Ortega (Lv 50)', 'pokemon': 'Wigglytuff, Dachsbun'},
        {'id': 'sv_s5', 'text': 'Fighting Crew - Eri (Lv 56)', 'pokemon': 'Primeape, Heracross'},
      ]},
      {'section': 'Endgame', 'steps': [
        {'id': 'sv_e1', 'text': 'Area Zero - The Way Home'},
        {'id': 'sv_e2', 'text': 'Academy Ace Tournament (repeatable)'},
        {'id': 'sv_e3', 'text': '5-Star and 6-Star Tera Raids'},
      ]},
    ],
    'Sword / Shield': [
      {'section': 'Getting Started', 'steps': [
        {'id': 'ss1', 'text': 'Choose starter: Grookey / Scorbunny / Sobble', 'pokemon': 'Grookey, Scorbunny, Sobble'},
        {'id': 'ss2', 'text': 'Route 1 - First catches', 'pokemon': 'Skwovet, Wooloo, Rookidee, Blipbug'},
      ]},
      {'section': 'Gym Challenge', 'steps': [
        {'id': 'ss_g1', 'text': 'Turffield Gym - Grass (Lv 19-20)', 'pokemon': 'Gossifleur, Eldegoss'},
        {'id': 'ss_g2', 'text': 'Hulbury Gym - Water (Lv 22-24)', 'pokemon': 'Arrokuda, Drednaw'},
        {'id': 'ss_g3', 'text': 'Motostoke Gym - Fire (Lv 25-27)', 'pokemon': 'Vulpix, Ninetales, Arcanine/Centiskorch'},
        {'id': 'ss_g4', 'text': 'Stow-on-Side Gym - Fighting/Ghost (Lv 34-36)', 'pokemon': 'Pangoro/Mimikyu'},
        {'id': 'ss_g5', 'text': 'Ballonlea Gym - Fairy (Lv 36-38)', 'pokemon': 'Mawile, Gardevoir, Alcremie'},
        {'id': 'ss_g6', 'text': 'Circhester Gym - Rock/Ice (Lv 40-42)', 'pokemon': 'Barbaracle/Mr. Rime'},
        {'id': 'ss_g7', 'text': 'Spikemuth Gym - Dark (Lv 44-46)', 'pokemon': 'Scrafty, Morpeko, Obstagoon'},
        {'id': 'ss_g8', 'text': 'Hammerlocke Gym - Dragon (Lv 47-48)', 'pokemon': 'Flygon, Haxorus, Duraludon'},
      ]},
      {'section': 'Endgame', 'steps': [
        {'id': 'ss_e1', 'text': 'Champion Cup Tournament'},
        {'id': 'ss_e2', 'text': 'Darkest Day postgame story'},
        {'id': 'ss_e3', 'text': 'Battle Tower'},
      ]},
    ],
    'Brilliant Diamond / Shining Pearl': [
      {'section': 'Getting Started', 'steps': [
        {'id': 'bd1', 'text': 'Choose starter: Turtwig / Chimchar / Piplup', 'pokemon': 'Turtwig, Chimchar, Piplup'},
        {'id': 'bd2', 'text': 'Route 201-203 catches', 'pokemon': 'Starly, Bidoof, Shinx, Kricketot, Abra'},
      ]},
      {'section': 'Gym Challenge', 'steps': [
        {'id': 'bd_g1', 'text': 'Oreburgh Gym - Rock (Lv 12-14)', 'pokemon': 'Geodude, Onix, Cranidos'},
        {'id': 'bd_g2', 'text': 'Eterna Gym - Grass (Lv 19-22)', 'pokemon': 'Turtwig, Cherrim, Roserade'},
        {'id': 'bd_g3', 'text': 'Veilstone Gym - Fighting (Lv 27-30)', 'pokemon': 'Meditite, Machoke, Lucario'},
        {'id': 'bd_g4', 'text': 'Pastoria Gym - Water (Lv 27-30)', 'pokemon': 'Gyarados, Quagsire, Floatzel'},
        {'id': 'bd_g5', 'text': 'Hearthome Gym - Ghost (Lv 32-36)', 'pokemon': 'Drifblim, Gengar, Mismagius'},
        {'id': 'bd_g6', 'text': 'Canalave Gym - Steel (Lv 36-39)', 'pokemon': 'Magneton, Steelix, Bastiodon'},
        {'id': 'bd_g7', 'text': 'Snowpoint Gym - Ice (Lv 38-42)', 'pokemon': 'Snover, Medicham, Abomasnow'},
        {'id': 'bd_g8', 'text': 'Sunyshore Gym - Electric (Lv 46-49)', 'pokemon': 'Raichu, Luxray, Electivire'},
      ]},
      {'section': 'Endgame', 'steps': [
        {'id': 'bd_e1', 'text': 'Elite Four and Cynthia'},
        {'id': 'bd_e2', 'text': 'National Dex unlock'},
        {'id': 'bd_e3', 'text': 'Ramanas Park (Legendaries)'},
        {'id': 'bd_e4', 'text': 'Battle Tower'},
      ]},
    ],
  };

  List<Map<String, dynamic>> get _currentWalkthrough =>
    _walkthroughs[_selectedGame] ?? [];

  int get _totalSteps {
    int count = 0;
    for (var section in _currentWalkthrough) {
      count += (section['steps'] as List).length;
    }
    return count;
  }

  int get _completedSteps => _completed.length;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Walkthrough'), backgroundColor: Colors.red),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedGame, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Game', border: OutlineInputBorder()),
              items: _walkthroughs.keys.map((g) =>
                DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) {
                setState(() => _selectedGame = v!);
                _loadProgress();
              },
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_completedSteps / $_totalSteps steps',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_totalSteps > 0 ? (_completedSteps * 100 ~/ _totalSteps) : 0}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _totalSteps > 0 ? _completedSteps / _totalSteps : 0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _currentWalkthrough.length,
              itemBuilder: (context, sectionIndex) {
                final section = _currentWalkthrough[sectionIndex];
                final steps = section['steps'] as List;
                final sectionCompleted = steps.every((s) => _completed.contains(s['id']));

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: Icon(
                      sectionCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: sectionCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(section['section'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: sectionCompleted ? TextDecoration.lineThrough : null,
                      )),
                    initiallyExpanded: !sectionCompleted,
                    children: steps.map<Widget>((step) {
                      final isDone = _completed.contains(step['id']);
                      return ListTile(
                        leading: Checkbox(
                          value: isDone,
                          onChanged: (_) => _toggleStep(step['id']),
                        ),
                        title: Text(step['text'],
                          style: TextStyle(
                            fontSize: 14,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey : null,
                          )),
                        subtitle: step['pokemon'] != null
                          ? Text('Available: ${step['pokemon']}',
                              style: const TextStyle(fontSize: 11, color: Colors.blue))
                          : null,
                        dense: true,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
