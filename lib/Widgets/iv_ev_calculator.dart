import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pokeapi_service.dart';
import '../services/pokemon_data_formatter.dart';

/// IV/EV Calculator Widget for Pokemon training
/// Supports all generations with proper stat calculations
class IVEVCalculator extends StatefulWidget {
  const IVEVCalculator({Key? key}) : super(key: key);

  @override
  State<IVEVCalculator> createState() => _IVEVCalculatorState();
}

class _IVEVCalculatorState extends State<IVEVCalculator> {
  // Pokemon selection
  String? _selectedPokemon;
  List<String> _pokemonNames = [];
  bool _isLoadingPokemon = true;
  Map<String, dynamic>? _pokemonData;

  // Controllers for stat inputs
  final Map<String, TextEditingController> _baseStatControllers = {
    'HP': TextEditingController(),
    'Attack': TextEditingController(),
    'Defense': TextEditingController(),
    'Sp. Atk': TextEditingController(),
    'Sp. Def': TextEditingController(),
    'Speed': TextEditingController(),
  };

  final Map<String, TextEditingController> _ivControllers = {
    'HP': TextEditingController(text: '31'),
    'Attack': TextEditingController(text: '31'),
    'Defense': TextEditingController(text: '31'),
    'Sp. Atk': TextEditingController(text: '31'),
    'Sp. Def': TextEditingController(text: '31'),
    'Speed': TextEditingController(text: '31'),
  };

  final Map<String, TextEditingController> _evControllers = {
    'HP': TextEditingController(text: '0'),
    'Attack': TextEditingController(text: '0'),
    'Defense': TextEditingController(text: '0'),
    'Sp. Atk': TextEditingController(text: '0'),
    'Sp. Def': TextEditingController(text: '0'),
    'Speed': TextEditingController(text: '0'),
  };

  final TextEditingController _levelController = TextEditingController(text: '100');

  String _selectedNature = 'Hardy';
  final List<String> _natures = [
    'Hardy', 'Lonely', 'Brave', 'Adamant', 'Naughty',
    'Bold', 'Docile', 'Relaxed', 'Impish', 'Lax',
    'Timid', 'Hasty', 'Serious', 'Jolly', 'Naive',
    'Modest', 'Mild', 'Quiet', 'Bashful', 'Rash',
    'Calm', 'Gentle', 'Sassy', 'Careful', 'Quirky',
  ];

  Map<String, int> _calculatedStats = {};
  int _totalEVs = 0;
  Map<String, int> _evYield = {};
  bool _showTrainingGuide = false;
  String _selectedGame = 'Scarlet/Violet';

  final List<String> _games = [
    'Red/Blue/Yellow',
    'Gold/Silver/Crystal',
    'Ruby/Sapphire/Emerald',
    'FireRed/LeafGreen',
    'Diamond/Pearl/Platinum',
    'HeartGold/SoulSilver',
    'Black/White',
    'Black 2/White 2',
    'X/Y',
    'Omega Ruby/Alpha Sapphire',
    'Sun/Moon',
    'Ultra Sun/Ultra Moon',
    'Sword/Shield',
    'Scarlet/Violet',
  ];

  @override
  void initState() {
    super.initState();
    _loadPokemonList();
    // Add listeners to EV controllers to track total EVs
    _evControllers.forEach((key, controller) {
      controller.addListener(_updateTotalEVs);
    });
  }

  Future<void> _loadPokemonList() async {
    try {
      final pokemonList = await PokeApiService.getPokemonList(limit: 1025);
      if (mounted) {
        setState(() {
          _pokemonNames = pokemonList
              .map((p) => PokemonDataFormatter.capitalize(p['name']))
              .toList();
          _isLoadingPokemon = false;
        });
      }
    } catch (e) {
      print('Error loading Pokemon list: $e');
      if (mounted) {
        setState(() {
          _isLoadingPokemon = false;
        });
      }
    }
  }

  Future<void> _loadPokemonData(String pokemonName) async {
    try {
      final data = await PokeApiService.getPokemon(pokemonName.toLowerCase());
      if (mounted) {
        setState(() {
          _pokemonData = data;
          _populateBaseStats(data);
          _extractEVYield(data);
        });
      }
    } catch (e) {
      print('Error loading Pokemon data: $e');
    }
  }

  void _populateBaseStats(Map<String, dynamic> data) {
    final stats = data['stats'] as List;
    final statMap = {
      'hp': 'HP',
      'attack': 'Attack',
      'defense': 'Defense',
      'special-attack': 'Sp. Atk',
      'special-defense': 'Sp. Def',
      'speed': 'Speed',
    };

    for (var stat in stats) {
      final statName = stat['stat']['name'];
      final baseStat = stat['base_stat'];
      final mappedName = statMap[statName];
      if (mappedName != null) {
        _baseStatControllers[mappedName]?.text = baseStat.toString();
      }
    }
  }

  void _extractEVYield(Map<String, dynamic> data) {
    final stats = data['stats'] as List;
    final statMap = {
      'hp': 'HP',
      'attack': 'Attack',
      'defense': 'Defense',
      'special-attack': 'Sp. Atk',
      'special-defense': 'Sp. Def',
      'speed': 'Speed',
    };

    _evYield.clear();
    for (var stat in stats) {
      final statName = stat['stat']['name'];
      final effort = stat['effort'];
      final mappedName = statMap[statName];
      if (mappedName != null && effort > 0) {
        _evYield[mappedName] = effort;
      }
    }
  }

  @override
  void dispose() {
    _baseStatControllers.forEach((key, controller) => controller.dispose());
    _ivControllers.forEach((key, controller) => controller.dispose());
    _evControllers.forEach((key, controller) => controller.dispose());
    _levelController.dispose();
    super.dispose();
  }

  void _updateTotalEVs() {
    int total = 0;
    _evControllers.forEach((key, controller) {
      total += int.tryParse(controller.text) ?? 0;
    });
    setState(() {
      _totalEVs = total;
    });
  }

  /// Get nature modifier for a stat
  double _getNatureModifier(String stat) {
    final natureEffects = {
      'Lonely': {'Attack': 1.1, 'Defense': 0.9},
      'Brave': {'Attack': 1.1, 'Speed': 0.9},
      'Adamant': {'Attack': 1.1, 'Sp. Atk': 0.9},
      'Naughty': {'Attack': 1.1, 'Sp. Def': 0.9},
      'Bold': {'Defense': 1.1, 'Attack': 0.9},
      'Relaxed': {'Defense': 1.1, 'Speed': 0.9},
      'Impish': {'Defense': 1.1, 'Sp. Atk': 0.9},
      'Lax': {'Defense': 1.1, 'Sp. Def': 0.9},
      'Timid': {'Speed': 1.1, 'Attack': 0.9},
      'Hasty': {'Speed': 1.1, 'Defense': 0.9},
      'Jolly': {'Speed': 1.1, 'Sp. Atk': 0.9},
      'Naive': {'Speed': 1.1, 'Sp. Def': 0.9},
      'Modest': {'Sp. Atk': 1.1, 'Attack': 0.9},
      'Mild': {'Sp. Atk': 1.1, 'Defense': 0.9},
      'Quiet': {'Sp. Atk': 1.1, 'Speed': 0.9},
      'Rash': {'Sp. Atk': 1.1, 'Sp. Def': 0.9},
      'Calm': {'Sp. Def': 1.1, 'Attack': 0.9},
      'Gentle': {'Sp. Def': 1.1, 'Defense': 0.9},
      'Sassy': {'Sp. Def': 1.1, 'Speed': 0.9},
      'Careful': {'Sp. Def': 1.1, 'Sp. Atk': 0.9},
    };

    return natureEffects[_selectedNature]?[stat] ?? 1.0;
  }

  /// Calculate final stat value
  /// Formula varies based on generation and stat type
  int _calculateStat(String statName) {
    final baseStat = int.tryParse(_baseStatControllers[statName]?.text ?? '0') ?? 0;
    final iv = int.tryParse(_ivControllers[statName]?.text ?? '0') ?? 0;
    final ev = int.tryParse(_evControllers[statName]?.text ?? '0') ?? 0;
    final level = int.tryParse(_levelController.text) ?? 100;

    if (baseStat == 0) return 0;

    int finalStat;

    if (statName == 'HP') {
      // HP stat calculation (Gen 3+)
      finalStat = (((2 * baseStat + iv + (ev / 4)) * level) / 100).floor() + level + 10;
    } else {
      // Other stats calculation (Gen 3+)
      final natureModifier = _getNatureModifier(statName);
      finalStat = ((((2 * baseStat + iv + (ev / 4)) * level) / 100) + 5).floor();
      finalStat = (finalStat * natureModifier).floor();
    }

    return finalStat;
  }

  void _calculateStats() {
    setState(() {
      _calculatedStats = {
        'HP': _calculateStat('HP'),
        'Attack': _calculateStat('Attack'),
        'Defense': _calculateStat('Defense'),
        'Sp. Atk': _calculateStat('Sp. Atk'),
        'Sp. Def': _calculateStat('Sp. Def'),
        'Speed': _calculateStat('Speed'),
      };
    });
  }

  /// Check if the selected game uses the modern EV system (Gen 3+)
  /// Gen 1-2 used "Stat Experience" instead
  bool _isModernEVSystem() {
    final gen1And2Games = [
      'Red/Blue/Yellow',
      'Gold/Silver/Crystal',
    ];
    return !gen1And2Games.contains(_selectedGame);
  }

  Widget _buildStatRow(String statName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              statName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _baseStatControllers[statName],
              decoration: const InputDecoration(
                labelText: 'Base',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ivControllers[statName],
              decoration: const InputDecoration(
                labelText: 'IV',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _RangeTextInputFormatter(min: 0, max: 31),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _evControllers[statName],
              decoration: const InputDecoration(
                labelText: 'EV',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _RangeTextInputFormatter(min: 0, max: 252),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              _calculatedStats[statName]?.toString() ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingSection(String statName, List<String> pokemon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$statName Training:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        ...pokemon.map((p) => Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  p,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        )).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _getTrainingGuideForGame() {
    Map<String, List<String>> guides = {};

    switch (_selectedGame) {
      case 'Red/Blue/Yellow':
        guides = {
          'HP': ['Chansey (+2 HP) - Unknown Dungeon, Safari Zone', 'Wigglytuff (+3 HP) - Evolve Jigglypuff'],
          'Attack': ['Machop (+1 Attack) - Rock Tunnel, Victory Road', 'Machoke (+2 Attack) - Victory Road, Cerulean Cave'],
          'Defense': ['Geodude (+1 Defense) - Mt. Moon, Rock Tunnel', 'Graveler (+2 Defense) - Victory Road, Cerulean Cave'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Pokemon Tower', 'Haunter (+2 Sp. Atk) - Pokemon Tower'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All water routes', 'Tentacruel (+2 Sp. Def) - Routes 19, 20, 21'],
          'Speed': ['Zubat (+1 Speed) - Mt. Moon, Rock Tunnel, all caves', 'Diglett (+1 Speed) - Diglett\'s Cave'],
        };
        break;

      case 'Gold/Silver/Crystal':
        guides = {
          'HP': ['Sentret (+1 HP) - Route 1, 29', 'Chansey (+2 HP) - Route 13, 14, 15', 'Blissey (+3 HP) - Evolve Chansey'],
          'Attack': ['Machop (+1 Attack) - Rock Tunnel', 'Pinsir (+2 Attack) - Headbutt trees'],
          'Defense': ['Geodude (+1 Defense) - Dark Cave, Union Cave', 'Graveler (+2 Defense) - Victory Road', 'Skarmory (+2 Defense) - Route 45'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Sprout Tower, Tin Tower', 'Haunter (+2 Sp. Atk) - Tin Tower'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - Routes 19, 20, 21, 40, 41', 'Tentacruel (+2 Sp. Def) - Routes 40, 41'],
          'Speed': ['Zubat (+1 Speed) - Dark Cave, Union Cave, all caves', 'Diglett (+1 Speed) - Diglett\'s Cave'],
        };
        break;

      case 'Ruby/Sapphire/Emerald':
        guides = {
          'HP': ['Marill (+2 HP) - Routes 102, 111, 114, 117, 120', 'Azumarill (+3 HP) - Evolve Marill', 'Wailmer (+1 HP) - Ocean routes'],
          'Attack': ['Poochyena (+1 Attack) - Route 101, 102, 103', 'Zigzagoon (+1 Attack) - Route 101, 102, 103', 'Medicham (+2 Attack) - Victory Road'],
          'Defense': ['Geodude (+1 Defense) - Granite Cave, Victory Road', 'Graveler (+2 Defense) - Victory Road', 'Aron (+1 Defense) - Granite Cave'],
          'Sp. Atk': ['Oddish (+1 Sp. Atk) - Route 110, 117, 119, 120', 'Roselia (+2 Sp. Atk) - Route 117', 'Ralts (+1 Sp. Atk) - Route 102'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All water routes', 'Tentacruel (+2 Sp. Def) - Deep water routes', 'Dustox (+3 Sp. Def) - Evolve Cascoon'],
          'Speed': ['Zubat (+1 Speed) - All caves', 'Wingull (+1 Speed) - All ocean routes', 'Taillow (+1 Speed) - Route 104, 115, 116'],
        };
        break;

      case 'FireRed/LeafGreen':
        guides = {
          'HP': ['Chansey (+2 HP) - Cerulean Cave', 'Wigglytuff (+3 HP) - Evolve Jigglypuff'],
          'Attack': ['Machop (+1 Attack) - Rock Tunnel, Victory Road', 'Machoke (+2 Attack) - Victory Road, Cerulean Cave'],
          'Defense': ['Geodude (+1 Defense) - Mt. Moon, Rock Tunnel', 'Graveler (+2 Defense) - Victory Road, Cerulean Cave'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Pokemon Tower', 'Haunter (+2 Sp. Atk) - Pokemon Tower'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All water routes', 'Tentacruel (+2 Sp. Def) - Routes 19, 20, 21'],
          'Speed': ['Zubat (+1 Speed) - Mt. Moon, Rock Tunnel, all caves', 'Diglett (+1 Speed) - Diglett\'s Cave'],
        };
        break;

      case 'Diamond/Pearl/Platinum':
        guides = {
          'HP': ['Bidoof (+1 HP) - Routes 201, 202, 203, 204, 205', 'Bibarel (+2 HP) - Routes 208, 209, 210'],
          'Attack': ['Shinx (+1 Attack) - Route 202, 203, 204', 'Luxio (+2 Attack) - Route 222', 'Machop (+1 Attack) - Route 207'],
          'Defense': ['Geodude (+1 Defense) - Oreburgh Gate, Oreburgh Mine', 'Graveler (+2 Defense) - Victory Road, Iron Island'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Old Chateau', 'Haunter (+2 Sp. Atk) - Old Chateau', 'Psyduck (+1 Sp. Atk) - Routes 203-205'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - Canalave City, Sunyshore City (surf)', 'Tentacruel (+2 Sp. Def) - Canalave City (surf)'],
          'Speed': ['Starly (+1 Speed) - Route 201, 202, 203, 204, 209', 'Staravia (+2 Speed) - Lake Verity, Lake Valor', 'Zubat (+1 Speed) - All caves'],
        };
        break;

      case 'HeartGold/SoulSilver':
        guides = {
          'HP': ['Sentret (+1 HP) - Route 1, 29', 'Chansey (+2 HP) - Route 13, 14, 15', 'Blissey (+3 HP) - Evolve Chansey'],
          'Attack': ['Machop (+1 Attack) - Rock Tunnel', 'Pinsir (+2 Attack) - Headbutt trees', 'Heracross (+2 Attack) - Headbutt trees'],
          'Defense': ['Geodude (+1 Defense) - Dark Cave, Union Cave', 'Graveler (+2 Defense) - Victory Road', 'Skarmory (+2 Defense) - Route 45'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Sprout Tower, Tin Tower', 'Haunter (+2 Sp. Atk) - Tin Tower'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All water routes', 'Tentacruel (+2 Sp. Def) - Routes 40, 41'],
          'Speed': ['Zubat (+1 Speed) - Dark Cave, Union Cave, all caves', 'Diglett (+1 Speed) - Diglett\'s Cave'],
        };
        break;

      case 'Black/White':
      case 'Black 2/White 2':
        guides = {
          'HP': ['Lillipup (+1 HP) - Route 1, 2, 3', 'Audino (+2 HP) - Rustling grass anywhere', 'Alomomola (+2 HP) - Surf spots'],
          'Attack': ['Patrat (+1 Attack) - Route 19, 20', 'Lillipup (+1 Attack) - Route 1, 2, 3', 'Basculin (+2 Attack) - All fishing spots'],
          'Defense': ['Roggenrola (+1 Defense) - Wellspring Cave', 'Boldore (+2 Defense) - Challenger\'s Cave', 'Sewaddle (+1 Defense) - Pinwheel Forest'],
          'Sp. Atk': ['Litwick (+1 Sp. Atk) - Celestial Tower', 'Lampent (+2 Sp. Atk) - Strange House', 'Solosis (+1 Sp. Atk) - Route 5'],
          'Sp. Def': ['Frillish (+1 Sp. Def) - All surf spots', 'Jellicent (+2 Sp. Def) - Deep water spots', 'Munna (+1 Sp. Def) - Dreamyard'],
          'Speed': ['Purrloin (+1 Speed) - Route 2, 3', 'Zubat (+1 Speed) - All caves', 'Woobat (+1 Speed) - Wellspring Cave'],
        };
        break;

      case 'X/Y':
        guides = {
          'HP': ['Gulpin (+1 HP) - Route 5', 'Swalot (+2 HP) - Route 19', 'Audino (+2 HP) - Yellow flowers'],
          'Attack': ['Furfrou (+1 Attack) - Route 5', 'Hawlucha (+2 Attack) - Route 10', 'Binacle (+1 Attack) - Ambrette Town rocks'],
          'Defense': ['Geodude (+1 Defense) - Terminus Cave', 'Graveler (+2 Defense) - Terminus Cave', 'Rhyhorn (+1 Defense) - Route 9'],
          'Sp. Atk': ['Psyduck (+1 Sp. Atk) - Route 7', 'Roselia (+2 Sp. Atk) - Route 7', 'Spoink (+1 Sp. Atk) - Route 8'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All surf spots', 'Tentacruel (+2 Sp. Def) - Deep water', 'Stunfisk (+2 Sp. Def) - Route 14'],
          'Speed': ['Bunnelby (+1 Speed) - Route 2, 3', 'Diggersby (+2 Speed) - Route 22', 'Fletchling (+1 Speed) - Route 2, 3'],
        };
        break;

      case 'Omega Ruby/Alpha Sapphire':
        guides = {
          'HP': ['Marill (+2 HP) - Routes 102, 111, 114, 117, 120', 'Azumarill (+3 HP) - Evolve Marill', 'Wailmer (+1 HP) - Ocean routes'],
          'Attack': ['Poochyena (+1 Attack) - Route 101, 102, 103', 'Zigzagoon (+1 Attack) - Route 101, 102, 103', 'Medicham (+2 Attack) - Victory Road'],
          'Defense': ['Geodude (+1 Defense) - Granite Cave, Victory Road', 'Graveler (+2 Defense) - Victory Road', 'Aron (+1 Defense) - Granite Cave'],
          'Sp. Atk': ['Oddish (+1 Sp. Atk) - Route 110, 117, 119, 120', 'Roselia (+2 Sp. Atk) - Route 117', 'Ralts (+1 Sp. Atk) - Route 102'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All water routes', 'Tentacruel (+2 Sp. Def) - Deep water routes', 'Dustox (+3 Sp. Def) - Evolve Cascoon'],
          'Speed': ['Zubat (+1 Speed) - All caves', 'Wingull (+1 Speed) - All ocean routes', 'Taillow (+1 Speed) - Route 104, 115, 116'],
        };
        break;

      case 'Sun/Moon':
      case 'Ultra Sun/Ultra Moon':
        guides = {
          'HP': ['Caterpie (+1 HP) - Route 1', 'Metapod (+2 HP) - Melemele Meadow', 'Chansey (+2 HP) - Paniola Ranch SOS'],
          'Attack': ['Yungoos (+1 Attack) - Route 1, 2', 'Gumshoos (+2 Attack) - Route 10, 15', 'Granbull (+2 Attack) - Route 2'],
          'Defense': ['Roggenrola (+1 Defense) - Ten Carat Hill', 'Boldore (+2 Defense) - Ten Carat Hill', 'Carbink (+1 Defense) - Ten Carat Hill rare'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Hau\'oli Cemetery', 'Haunter (+2 Sp. Atk) - Memorial Hill', 'Oricorio (+2 Sp. Atk) - Meadows and gardens'],
          'Sp. Def': ['Tentacool (+1 Sp. Def) - All surf spots', 'Tentacruel (+2 Sp. Def) - Deep ocean', 'Frillish (+1 Sp. Def) - Poni Wilds surf'],
          'Speed': ['Zubat (+1 Speed) - All caves', 'Diglett (+1 Speed) - Verdant Cavern', 'Alolan Diglett (+1 Speed) - Diglett\'s Tunnel'],
        };
        break;

      case 'Sword/Shield':
        guides = {
          'HP': ['Skwovet (+1 HP) - Route 1', 'Wooloo (+1 HP) - Route 1', 'Chansey (+2 HP) - Lake of Outrage'],
          'Attack': ['Chewtle (+1 Attack) - Route 2 water', 'Drednaw (+2 Attack) - Wild Area water', 'Rookidee (+1 Attack) - Route 1'],
          'Defense': ['Rolycoly (+1 Defense) - Galar Mine', 'Carkol (+2 Defense) - Galar Mine No. 2', 'Ferroseed (+1 Defense) - Route 6'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - Watchtower Ruins', 'Haunter (+2 Sp. Atk) - Giant\'s Cap', 'Litwick (+1 Sp. Atk) - Watchtower Ruins'],
          'Sp. Def': ['Gossifleur (+1 Sp. Def) - Route 3', 'Eldegoss (+2 Sp. Def) - Rolling Fields', 'Applin (+1 Sp. Def) - Route 5'],
          'Speed': ['Rookidee (+1 Speed) - Route 1, 2', 'Corvisquire (+2 Speed) - Bridge Field, Giant\'s Cap', 'Sizzlipede (+1 Speed) - Route 3'],
        };
        break;

      case 'Scarlet/Violet':
        guides = {
          'HP': ['Lechonk (+1 HP) - South Province Area 1', 'Azurill (+1 HP) - South Province Area 1', 'Chansey (+2 HP) - North Province Area 3'],
          'Attack': ['Yungoos (+1 Attack) - South Province Area 1', 'Primeape (+2 Attack) - South Province Area 4', 'Mankey (+1 Attack) - South Province Area 4'],
          'Defense': ['Nacli (+1 Defense) - South Province Area 3', 'Naclstack (+2 Defense) - Glaseado Mountain', 'Pineco (+1 Defense) - East Province Area 2'],
          'Sp. Atk': ['Gastly (+1 Sp. Atk) - South Province Area 3 night', 'Haunter (+2 Sp. Atk) - Glaseado Mountain night', 'Psyduck (+1 Sp. Atk) - South Province Area 2'],
          'Sp. Def': ['Shellos (+1 Sp. Def) - Beach areas', 'Gastrodon (+2 Sp. Def) - Beach areas', 'Finizen (+1 Sp. Def) - All ocean areas'],
          'Speed': ['Rookidee (+1 Speed) - South Province Area 1', 'Fletchling (+1 Speed) - South Province Area 1', 'Wingull (+1 Speed) - Coastal areas'],
        };
        break;

      default:
        guides = {
          'HP': ['Chansey (+2 HP)', 'Blissey (+3 HP)'],
          'Attack': ['Machop/Machoke (+1/+2 Attack)'],
          'Defense': ['Geodude/Graveler (+1/+2 Defense)'],
          'Sp. Atk': ['Gastly/Haunter (+1/+2 Sp. Atk)'],
          'Sp. Def': ['Tentacool/Tentacruel (+1/+2 Sp. Def)'],
          'Speed': ['Zubat (+1 Speed)', 'Diglett (+1 Speed)'],
        };
    }

    return guides.entries.map((entry) {
      return _buildTrainingSection(entry.key, entry.value);
    }).toList();
  }

  List<Widget> _getProTipsForGame() {
    List<String> tips = [
      '• Use Pokerus for 2x EV gains (works in all games)',
      '• Vitamins: HP Up, Protein, Iron, Calcium, Zinc, Carbos (+10 EVs up to 100)',
    ];

    if (_selectedGame == 'Red/Blue/Yellow' || _selectedGame == 'Gold/Silver/Crystal') {
      tips.addAll([
        '• No held items for EV training in Gen 1-2',
        '• Vitamins can be bought at department stores',
      ]);
    } else if (_selectedGame.contains('Ruby') || _selectedGame.contains('Sapphire') ||
               _selectedGame.contains('Emerald') || _selectedGame.contains('FireRed') ||
               _selectedGame.contains('LeafGreen')) {
      tips.addAll([
        '• Power items not available yet',
        '• Macho Brace (2x EV gains, but halves Speed) - Obtained from Winstrate family',
      ]);
    } else if (_selectedGame.contains('Diamond') || _selectedGame.contains('Pearl') ||
               _selectedGame.contains('Platinum') || _selectedGame.contains('HeartGold') ||
               _selectedGame.contains('SoulSilver')) {
      tips.addAll([
        '• Power items available! (+8 EVs to specific stat)',
        '  - Power Weight (HP), Power Bracer (Attack), Power Belt (Defense)',
        '  - Power Lens (Sp. Atk), Power Band (Sp. Def), Power Anklet (Speed)',
        '• Buy Power items at Battle Tower for 16 BP each',
        '• Macho Brace (2x EV gains, but halves Speed)',
      ]);
    } else if (_selectedGame.contains('Black') || _selectedGame.contains('White')) {
      tips.addAll([
        '• Power items (+8 EVs, buy at Battle Subway for 16 BP)',
        '• Macho Brace (2x EV gains)',
      ]);
    } else if (_selectedGame == 'X/Y' || _selectedGame.contains('Omega Ruby') ||
               _selectedGame.contains('Alpha Sapphire')) {
      tips.addAll([
        '• Power items (+8 EVs, buy at Battle Maison for 16 BP)',
        '• Super Training for targeted EV training',
        '• Horde Battles give 5x EVs at once!',
      ]);
    } else if (_selectedGame.contains('Sun') || _selectedGame.contains('Moon')) {
      tips.addAll([
        '• Power items (+8 EVs, buy at Battle Tree for 16 BP)',
        '• SOS Battles: Each SOS Pokemon gives EVs',
        '• Adrenaline Orb to trigger SOS battles',
      ]);
    } else if (_selectedGame == 'Sword/Shield') {
      tips.addAll([
        '• Power items (+8 EVs, buy at Hammerlocke BP shop)',
        '• Poke Jobs for automatic EV training!',
        '• Send Pokemon on jobs for easy EVs',
        '• Vitamins now work up to 252 EVs (game changer!)',
      ]);
    } else if (_selectedGame == 'Scarlet/Violet') {
      tips.addAll([
        '• Power items (+8 EVs, buy at Delibird Presents)',
        '• Vitamins work up to 252 EVs!',
        '• EV-reducing berries available at Porto Marinada auction',
        '• Use picnics to make sandwiches for encounter boosts',
      ]);
    }

    return tips.map((tip) => Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(tip, style: const TextStyle(fontSize: 12)),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.red,
            child: const Row(
              children: [
                Icon(Icons.calculate, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'IV/EV Calculator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            const Text(
              'Pokemon Training Calculator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a Pokemon or manually enter base stats to calculate final stats.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Pokemon Selection
            if (_isLoadingPokemon)
              const Center(child: CircularProgressIndicator())
            else
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _pokemonNames.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  }).take(10);
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedPokemon = selection;
                  });
                  _loadPokemonData(selection);
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Select Pokemon',
                      hintText: 'Start typing Pokemon name...',
                      prefixIcon: const Icon(Icons.catching_pokemon),
                      border: const OutlineInputBorder(),
                      suffixIcon: fieldTextEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                fieldTextEditingController.clear();
                                setState(() {
                                  _selectedPokemon = null;
                                  _pokemonData = null;
                                  _evYield.clear();
                                });
                              },
                            )
                          : null,
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // EV Yield Information (only for Gen 3+ games)
            if (_evYield.isNotEmpty && _isModernEVSystem())
              Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EV Yield (Defeating this Pokemon gives):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ..._evYield.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '${entry.key}: +${entry.value} EV',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      Text(
                        'Defeat ${_selectedPokemon ?? 'this Pokemon'} to train these stats!',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Gen 1-2 Notice (Stat Experience instead of EVs)
            if (_evYield.isNotEmpty && !_isModernEVSystem())
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Stat Experience System',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedGame} uses the Stat Experience system, not EVs. '
                        'Defeating any Pokemon gives Stat Exp equal to its base stats. '
                        'See the training guide below for recommended Pokemon.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Level and Nature inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _levelController,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _RangeTextInputFormatter(min: 1, max: 100),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedNature,
                    decoration: const InputDecoration(
                      labelText: 'Nature',
                      border: OutlineInputBorder(),
                    ),
                    items: _natures.map((nature) {
                      return DropdownMenuItem(
                        value: nature,
                        child: Text(nature),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedNature = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // EV Total Counter
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _totalEVs > 510
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _totalEVs > 510 ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total EVs:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '$_totalEVs / 510',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _totalEVs > 510 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stat rows header
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 70),
                  Expanded(child: Text('Base', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 8),
                  Expanded(child: Text('IV', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 8),
                  Expanded(child: Text('EV', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('Total', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(),

            // Stat rows
            _buildStatRow('HP'),
            _buildStatRow('Attack'),
            _buildStatRow('Defense'),
            _buildStatRow('Sp. Atk'),
            _buildStatRow('Sp. Def'),
            _buildStatRow('Speed'),

            const SizedBox(height: 24),

            // Calculate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Calculate Stats',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Game Selection
            DropdownButtonFormField<String>(
              value: _selectedGame,
              decoration: const InputDecoration(
                labelText: 'Select Your Game',
                prefixIcon: Icon(Icons.videogame_asset),
                border: OutlineInputBorder(),
              ),
              items: _games.map((game) {
                return DropdownMenuItem(
                  value: game,
                  child: Text(game),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGame = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // EV Training Guide Toggle
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showTrainingGuide = !_showTrainingGuide;
                });
              },
              icon: Icon(_showTrainingGuide ? Icons.expand_less : Icons.expand_more),
              label: Text(_showTrainingGuide ? 'Hide EV Training Guide' : 'Show EV Training Guide for $_selectedGame'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // EV Training Guide
            if (_showTrainingGuide)
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EV Training Guide - $_selectedGame',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Best Pokemon to defeat for each stat:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ..._getTrainingGuideForGame(),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Pro Tips for $_selectedGame:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ..._getProTipsForGame(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Info text
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Select a Pokemon to auto-fill base stats'),
                    Text('• EV Yield shows what EVs you gain from defeating that Pokemon'),
                    Text('• IVs range from 0-31 (individual values)'),
                    Text('• EVs range from 0-252 per stat, 510 total'),
                    Text('• Each 4 EVs = 1 stat point at level 100'),
                    Text('• Nature affects stats by ±10%'),
                    Text('• Neutral natures: Hardy, Docile, Serious, Bashful, Quirky'),
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Input formatter to limit values to a specific range
class _RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}
