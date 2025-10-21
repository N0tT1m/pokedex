import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:advanced_search/advanced_search.dart';
import 'package:uuid/uuid.dart';
import '../services/pokeapi_service.dart';
import '../services/iv_calculator_service.dart';
import '../services/pokemon_storage_service.dart';
import '../services/pokemondb_service.dart';
import '../models/saved_pokemon.dart';

class ReverseIVCalculator extends StatefulWidget {
  const ReverseIVCalculator({Key? key}) : super(key: key);

  @override
  State<ReverseIVCalculator> createState() => _ReverseIVCalculatorState();
}

class _ReverseIVCalculatorState extends State<ReverseIVCalculator> {
  final _storageService = PokemonStorageService();

  // Pokemon selection
  List<String> _pokemonList = [];
  String? _selectedPokemon;
  Map<String, dynamic>? _pokemonData;
  Map<String, List<String>> _encounterData = {};

  // Form controllers
  final _levelController = TextEditingController(text: '50');
  final _nicknameController = TextEditingController();

  // Stat controllers for observed stats
  final Map<String, TextEditingController> _observedStatControllers = {
    'HP': TextEditingController(),
    'Attack': TextEditingController(),
    'Defense': TextEditingController(),
    'Sp. Atk': TextEditingController(),
    'Sp. Def': TextEditingController(),
    'Speed': TextEditingController(),
  };

  // EV controllers (user can input known EVs, default to 0)
  final Map<String, TextEditingController> _evControllers = {
    'HP': TextEditingController(text: '0'),
    'Attack': TextEditingController(text: '0'),
    'Defense': TextEditingController(text: '0'),
    'Sp. Atk': TextEditingController(text: '0'),
    'Sp. Def': TextEditingController(text: '0'),
    'Speed': TextEditingController(text: '0'),
  };

  // Calculated IV ranges
  Map<String, Map<String, int>> _calculatedIVRanges = {};

  // Selected nature
  String _selectedNature = 'Hardy';

  // Additional Pokemon info
  bool _isShiny = false;
  String? _gender;
  String? _ability;
  String? _location;
  String? _game;
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  // Common game versions
  static const List<String> gameVersions = [
    'Scarlet/Violet',
    'Sword/Shield',
    'Brilliant Diamond/Shining Pearl',
    'Legends: Arceus',
    'Let\'s Go Pikachu/Eevee',
    'Ultra Sun/Ultra Moon',
    'Sun/Moon',
    'Omega Ruby/Alpha Sapphire',
    'X/Y',
    'Black 2/White 2',
    'Black/White',
    'HeartGold/SoulSilver',
    'Platinum',
    'Diamond/Pearl',
    'Emerald',
    'FireRed/LeafGreen',
    'Ruby/Sapphire',
    'Crystal',
    'Gold/Silver',
    'Yellow',
    'Red/Blue',
  ];

  @override
  void initState() {
    super.initState();
    _loadPokemonList();
  }

  Future<void> _loadPokemonList() async {
    setState(() => _isLoading = true);
    try {
      final results = await PokeApiService.getPokemonList(limit: 1025);
      setState(() {
        _pokemonList = results.map((p) => p['name'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load Pokemon list: $e');
    }
  }

  Future<void> _loadPokemonData(String pokemonName) async {
    setState(() => _isLoading = true);
    try {
      // Load Pokemon data from PokeAPI
      final data = await PokeApiService.getPokemon(pokemonName.toLowerCase());

      // Load encounter locations from PokemonDB
      final encounters = await PokemonDBService.getEncounterLocations(pokemonName);

      setState(() {
        _pokemonData = data;
        _encounterData = encounters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load Pokemon data: $e');
    }
  }

  void _calculateIVs() {
    if (_pokemonData == null) {
      _showError('Please select a Pokemon first');
      return;
    }

    // Get base stats
    final Map<String, int> baseStats = {};
    final stats = _pokemonData!['stats'] as List;
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
        baseStats[mappedName] = baseStat;
      }
    }

    // Get observed stats
    final Map<String, int> observedStats = {};
    for (var entry in _observedStatControllers.entries) {
      final value = int.tryParse(entry.value.text);
      if (value == null || value <= 0) {
        _showError('Please enter valid ${entry.key} stat');
        return;
      }
      observedStats[entry.key] = value;
    }

    // Get EVs
    final Map<String, int> evs = {};
    for (var entry in _evControllers.entries) {
      evs[entry.key] = int.tryParse(entry.value.text) ?? 0;
    }

    // Validate total EVs
    final totalEVs = evs.values.fold(0, (sum, ev) => sum + ev);
    if (totalEVs > 510) {
      _showError('Total EVs cannot exceed 510 (currently: $totalEVs)');
      return;
    }

    final level = int.tryParse(_levelController.text);
    if (level == null || level < 1 || level > 100) {
      _showError('Please enter a valid level (1-100)');
      return;
    }

    // Calculate IV ranges
    final ivRanges = IVCalculatorService.reverseCalculateIVs(
      baseStats: baseStats,
      observedStats: observedStats,
      level: level,
      evs: evs,
      nature: _selectedNature,
    );

    setState(() {
      _calculatedIVRanges = ivRanges;
    });

    _showSuccess('IVs calculated successfully!');
  }

  Future<void> _savePokemon() async {
    if (_pokemonData == null || _calculatedIVRanges.isEmpty) {
      _showError('Please calculate IVs first');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get base stats
      final Map<String, int> baseStats = {};
      final stats = _pokemonData!['stats'] as List;
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
          baseStats[mappedName] = baseStat;
        }
      }

      // Use mid-point of IV range as the IV value
      final Map<String, int> ivs = {};
      for (var entry in _calculatedIVRanges.entries) {
        final min = entry.value['min'] ?? 0;
        final max = entry.value['max'] ?? 31;
        ivs[entry.key] = ((min + max) / 2).round();
      }

      // Get EVs
      final Map<String, int> evs = {};
      for (var entry in _evControllers.entries) {
        evs[entry.key] = int.tryParse(entry.value.text) ?? 0;
      }

      // Get observed stats (these are the calculated stats)
      final Map<String, int> calculatedStats = {};
      for (var entry in _observedStatControllers.entries) {
        calculatedStats[entry.key] = int.tryParse(entry.value.text) ?? 0;
      }

      // Get sprite URL
      String? spriteUrl;
      try {
        spriteUrl = _pokemonData!['sprites']['front_default'];
      } catch (e) {
        // Ignore sprite errors
      }

      // Create SavedPokemon object
      final pokemon = SavedPokemon(
        id: const Uuid().v4(),
        speciesName: _selectedPokemon!,
        nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
        level: int.parse(_levelController.text),
        nature: _selectedNature,
        baseStats: baseStats,
        ivs: ivs,
        evs: evs,
        calculatedStats: calculatedStats,
        spriteUrl: spriteUrl,
        caughtDate: DateTime.now(),
        location: _location,
        ability: _ability,
        isShiny: _isShiny,
        gender: _gender,
        game: _game,
      );

      await _storageService.savePokemon(pokemon);

      setState(() => _isSaving = false);

      _showSuccess('Pokemon saved successfully!');

      // Optionally reset form
      final shouldReset = await _showConfirmDialog(
        'Pokemon Saved',
        'Would you like to add another Pokemon?',
      );
      if (shouldReset == true) {
        _resetForm();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save Pokemon: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPokemon = null;
      _pokemonData = null;
      _encounterData = {};
      _calculatedIVRanges = {};
      _nicknameController.clear();
      _locationController.clear();
      _levelController.text = '50';
      _selectedNature = 'Hardy';
      _isShiny = false;
      _gender = null;
      _ability = null;
      _location = null;
      _game = null;

      for (var controller in _observedStatControllers.values) {
        controller.clear();
      }
      for (var controller in _evControllers.values) {
        controller.text = '0';
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IV Checker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPokemonSelector(),
                  const SizedBox(height: 16),
                  if (_pokemonData != null) ...[
                    // Show encounter locations immediately after selection
                    if (_encounterData.isNotEmpty) ...[
                      _buildEncounterLocationsCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildBasicInfo(),
                    const SizedBox(height: 16),
                    _buildStatInputs(),
                    const SizedBox(height: 16),
                    _buildEVInputs(),
                    const SizedBox(height: 16),
                    _buildCalculateButton(),
                    const SizedBox(height: 16),
                    if (_calculatedIVRanges.isNotEmpty) ...[
                      _buildIVResults(),
                      const SizedBox(height: 16),
                      _buildAdditionalInfo(),
                      const SizedBox(height: 16),
                      _buildSaveButton(),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPokemonSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Pokemon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AdvancedSearch(
              searchItems: _pokemonList,
              maxElementsToDisplay: 10,
              singleItemHeight: 50,
              borderColor: Colors.grey,
              minLettersForSearch: 0,
              fontSize: 14,
              borderRadius: 12.0,
              hintText: 'Search Pokemon...',
              cursorColor: Colors.blueGrey,
              searchResultsBgColor: Colors.white,
              searchMode: SearchMode.CONTAINS,
              itemsShownAtStart: 10,
              onItemTap: (index, value) {
                setState(() {
                  _selectedPokemon = value;
                });
                _loadPokemonData(value);
              },
              onSearchClear: () {},
              onSubmitted: (value, value2) {},
              onEditingProgress: (value, value2) {},
            ),
            if (_selectedPokemon != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: ${_selectedPokemon![0].toUpperCase()}${_selectedPokemon!.substring(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _levelController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Level',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedNature,
              decoration: const InputDecoration(
                labelText: 'Nature',
                border: OutlineInputBorder(),
              ),
              items: IVCalculatorService.allNatures
                  .map((nature) => DropdownMenuItem(
                        value: nature,
                        child: Text(nature),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNature = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Pokemon\'s current stats as shown in-game',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...IVCalculatorService.statNames.map((statName) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _observedStatControllers[statName],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: statName,
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEVInputs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EVs (Effort Values)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter known EVs (leave at 0 if freshly caught)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...IVCalculatorService.statNames.map((statName) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _evControllers[statName],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '$statName EV',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculateIVs,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.blue,
      ),
      child: const Text(
        'Calculate IVs',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildIVResults() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculated IV Ranges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...IVCalculatorService.statNames.map((statName) {
              final range = _calculatedIVRanges[statName];
              if (range == null) return const SizedBox.shrink();

              final min = range['min'] ?? 0;
              final max = range['max'] ?? 31;
              final isApproximate = range.containsKey('approximate');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      min == max
                          ? '$min IV${isApproximate ? ' (approx)' : ''}'
                          : '$min-$max IV${isApproximate ? ' (approx)' : ''}',
                      style: TextStyle(
                        color: min == max ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            _buildTotalIVs(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalIVs() {
    int minTotal = 0;
    int maxTotal = 0;

    for (var range in _calculatedIVRanges.values) {
      minTotal += range['min'] ?? 0;
      maxTotal += range['max'] ?? 31;
    }

    final avgTotal = ((minTotal + maxTotal) / 2).round();
    final percentage = ((avgTotal / 186) * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total IVs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$avgTotal / 186 ($percentage%)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Info (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Shiny'),
              value: _isShiny,
              onChanged: (value) {
                setState(() {
                  _isShiny = value;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Unknown')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Genderless', child: Text('Genderless')),
              ],
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _game,
              decoration: const InputDecoration(
                labelText: 'Game Version',
                border: OutlineInputBorder(),
                hintText: 'Select game (optional)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not specified')),
                ...gameVersions.map((game) => DropdownMenuItem(
                      value: game,
                      child: Text(game),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _game = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ability (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Intimidate',
              ),
              onChanged: (value) {
                _ability = value.isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 12),
            // Show encounter locations if available
            if (_encounterData.isNotEmpty) ...[
              _buildEncounterLocations(),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location caught (optional)',
                border: const OutlineInputBorder(),
                hintText: _encounterData.isNotEmpty
                    ? 'Select from encounters above or type custom location'
                    : 'e.g., Lake of Outrage, Route 10',
                helperText: _encounterData.isNotEmpty
                    ? 'Tap a location above to auto-fill'
                    : 'Where you caught this Pokemon',
              ),
              onChanged: (value) {
                _location = value.isEmpty ? null : value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncounterLocationsCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Where to Find This Pokemon',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._encounterData.entries.map((entry) {
              final game = entry.key;
              final locations = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: locations.map((location) {
                        return Chip(
                          label: Text(
                            location,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Text(
              'Tip: Select your game version below to filter locations',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncounterLocations() {
    // Get locations for selected game, or all locations if no game selected
    List<String> locations = [];
    String title = 'Available Locations';

    if (_game != null) {
      final gameLocations = PokemonDBService.getLocationsForGame(
        _encounterData,
        _game!,
      );
      if (gameLocations != null && gameLocations.isNotEmpty) {
        locations = gameLocations;
        title = 'Locations in $_game';
      } else {
        locations = PokemonDBService.getAllLocations(_encounterData);
        title = 'All Game Locations';
      }
    } else {
      locations = PokemonDBService.getAllLocations(_encounterData);
    }

    if (locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: locations.take(15).map((location) {
            return ActionChip(
              label: Text(
                location,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                setState(() {
                  _locationController.text = location;
                  _location = location;
                });
              },
              backgroundColor: Colors.blue.withOpacity(0.1),
            );
          }).toList(),
        ),
        if (locations.length > 15) ...[
          const SizedBox(height: 4),
          Text(
            '+ ${locations.length - 15} more locations',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _savePokemon,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.green,
      ),
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'Save Pokemon',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
    );
  }

  @override
  void dispose() {
    _levelController.dispose();
    _nicknameController.dispose();
    for (var controller in _observedStatControllers.values) {
      controller.dispose();
    }
    for (var controller in _evControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
