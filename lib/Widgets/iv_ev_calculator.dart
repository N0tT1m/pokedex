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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IV/EV Calculator'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
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

            // EV Yield Information
            if (_evYield.isNotEmpty)
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
