import 'package:flutter/material.dart';
import '../../services/type_effectiveness_service.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

/// Screen where users select multiple types to find Pokemon strong against
/// that type combination, and see the full defensive/offensive breakdown.
class TypeStrengthFinderScreen extends StatefulWidget {
  const TypeStrengthFinderScreen({Key? key}) : super(key: key);

  @override
  State<TypeStrengthFinderScreen> createState() => _TypeStrengthFinderScreenState();
}

class _TypeStrengthFinderScreenState extends State<TypeStrengthFinderScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _selectedTypes = [];
  late TabController _tabController;

  // Computed matchup data
  Map<String, double> _defensiveMatchups = {};
  List<_TypeGroup> _weakTo = [];
  List<_TypeGroup> _resistantTo = [];
  List<_TypeGroup> _immuneTo = [];

  // Pokemon that are strong against the selected types (offensive)
  List<_RecommendedPokemon> _strongPokemon = [];
  bool _loadingPokemon = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else if (_selectedTypes.length < 5) {
        _selectedTypes.add(type);
      }
    });
    _recalculate();
  }

  void _recalculate() {
    if (_selectedTypes.isEmpty) {
      setState(() {
        _defensiveMatchups = {};
        _weakTo = [];
        _resistantTo = [];
        _immuneTo = [];
        _strongPokemon = [];
      });
      return;
    }

    final matchups = TypeEffectivenessService.getDefensiveMatchups(_selectedTypes);

    final weak = <_TypeGroup>[];
    final resist = <_TypeGroup>[];
    final immune = <_TypeGroup>[];

    for (var entry in matchups.entries) {
      if (entry.value > 1.0) {
        weak.add(_TypeGroup(entry.key, entry.value));
      } else if (entry.value > 0 && entry.value < 1.0) {
        resist.add(_TypeGroup(entry.key, entry.value));
      } else if (entry.value == 0) {
        immune.add(_TypeGroup(entry.key, entry.value));
      }
    }

    weak.sort((a, b) => b.multiplier.compareTo(a.multiplier));
    resist.sort((a, b) => a.multiplier.compareTo(b.multiplier));

    setState(() {
      _defensiveMatchups = matchups;
      _weakTo = weak;
      _resistantTo = resist;
      _immuneTo = immune;
    });

    _findStrongPokemon();
  }

  Future<void> _findStrongPokemon() async {
    if (_selectedTypes.isEmpty) return;

    setState(() => _loadingPokemon = true);

    try {
      // Find types that are super effective against the selected combo
      final effectiveTypes = _weakTo.map((g) => g.type).toList();

      if (effectiveTypes.isEmpty) {
        setState(() {
          _strongPokemon = [];
          _loadingPokemon = false;
        });
        return;
      }

      // Fetch Pokemon for each super-effective type
      final Map<String, Set<String>> pokemonByType = {};
      final Map<String, List<String>> pokemonTypes = {};

      for (var typeName in effectiveTypes) {
        try {
          final typeData = await PokeApiService.getType(typeName.toLowerCase());
          final pokemonList = typeData['pokemon'] as List? ?? [];

          for (var entry in pokemonList) {
            final pokemonEntry = entry['pokemon'];
            final name = pokemonEntry['name'] as String;
            // Skip mega/gmax/totem forms
            if (name.contains('-mega') ||
                name.contains('-gmax') ||
                name.contains('-totem')) {
              continue;
            }

            pokemonByType.putIfAbsent(typeName, () => {});
            pokemonByType[typeName]!.add(name);

            pokemonTypes.putIfAbsent(name, () => []);
            if (!pokemonTypes[name]!.contains(typeName)) {
              pokemonTypes[name]!.add(typeName);
            }
          }
        } catch (_) {}
      }

      // Score Pokemon: prefer those covering multiple weaknesses
      // and those that also resist the selected types
      final scored = <_RecommendedPokemon>[];
      final seen = <String>{};

      for (var entry in pokemonTypes.entries) {
        if (seen.contains(entry.key)) continue;
        seen.add(entry.key);

        final coverCount = entry.value.length;
        // Bonus if the Pokemon's attacking types cover more weaknesses
        final superEffectiveTypes = entry.value;

        // Check if this Pokemon resists the selected types (STAB defense)
        // We only know its offensive types from the type API, but that's
        // a reasonable proxy for its actual types
        double bestMultiplier = 4.0;
        for (var selType in _selectedTypes) {
          for (var pokType in superEffectiveTypes) {
            final mult = TypeEffectivenessService.getEffectiveness(selType, pokType);
            if (mult < bestMultiplier) bestMultiplier = mult;
          }
        }

        scored.add(_RecommendedPokemon(
          name: entry.key,
          types: superEffectiveTypes,
          coverageCount: coverCount,
          takesReducedDamage: bestMultiplier < 1.0,
        ));
      }

      // Sort: most coverage first, then those that resist
      scored.sort((a, b) {
        if (a.coverageCount != b.coverageCount) {
          return b.coverageCount.compareTo(a.coverageCount);
        }
        if (a.takesReducedDamage != b.takesReducedDamage) {
          return a.takesReducedDamage ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

      setState(() {
        _strongPokemon = scored.take(100).toList();
        _loadingPokemon = false;
      });
    } catch (e) {
      setState(() => _loadingPokemon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Type Strength Finder'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Matchups'),
            Tab(text: 'Strong Pokemon'),
            Tab(text: 'Full Chart'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTypeSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchupsTab(),
                _buildStrongPokemonTab(),
                _buildFullChartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedTypes.isEmpty
                ? 'Select 1-5 types to analyze'
                : 'Selected: ${_selectedTypes.join(" / ")}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TypeEffectivenessService.allTypes.map((type) {
              final selected = _selectedTypes.contains(type);
              final color = AppTheme.typeColors[type] ?? Colors.grey;
              return GestureDetector(
                onTap: () => _toggleType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? Border.all(color: Colors.white, width: 2)
                        : Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTypes.clear());
                  _recalculate();
                },
                child: const Text(
                  'Clear selection',
                  style: TextStyle(color: Colors.white54, decoration: TextDecoration.underline),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchupsTab() {
    if (_selectedTypes.isEmpty) {
      return const Center(
        child: Text('Select types above to see matchups', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_weakTo.isNotEmpty) ...[
          _sectionHeader('Weak to (takes extra damage)', Colors.red),
          ..._weakTo.map((g) => _matchupTile(g, Colors.red)),
          const SizedBox(height: 16),
        ],
        if (_resistantTo.isNotEmpty) ...[
          _sectionHeader('Resistant to (takes reduced damage)', Colors.green),
          ..._resistantTo.map((g) => _matchupTile(g, Colors.green)),
          const SizedBox(height: 16),
        ],
        if (_immuneTo.isNotEmpty) ...[
          _sectionHeader('Immune to (no damage)', Colors.blue),
          ..._immuneTo.map((g) => _matchupTile(g, Colors.blue)),
          const SizedBox(height: 16),
        ],
        _buildSummaryCard(),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _matchupTile(_TypeGroup g, Color indicatorColor) {
    final color = AppTheme.typeColors[g.type] ?? Colors.grey;
    final label = g.multiplier == 0
        ? '0x'
        : g.multiplier >= 1
            ? '${g.multiplier}x'
            : '${g.multiplier}x';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              g.type,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: indicatorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: indicatorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final typeStr = _selectedTypes.join('/');
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$typeStr Summary',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_weakTo.length} weaknesses, '
              '${_resistantTo.length} resistances, '
              '${_immuneTo.length} immunities',
              style: const TextStyle(color: Colors.white70),
            ),
            if (_weakTo.any((g) => g.multiplier >= 4)) ...[
              const SizedBox(height: 4),
              Text(
                '4x weak to: ${_weakTo.where((g) => g.multiplier >= 4).map((g) => g.type).join(", ")}',
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStrongPokemonTab() {
    if (_selectedTypes.isEmpty) {
      return const Center(
        child: Text('Select types above to find counters', style: TextStyle(color: Colors.white54)),
      );
    }

    if (_loadingPokemon) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_strongPokemon.isEmpty) {
      return const Center(
        child: Text('No Pokemon found with super-effective coverage',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            'Pokemon strong against ${_selectedTypes.join("/")} (${_strongPokemon.length} found)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _strongPokemon.length,
            itemBuilder: (context, index) {
              final p = _strongPokemon[index];
              return Card(
                color: Colors.grey[850],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.typeColors[p.types.first] ?? Colors.grey,
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    _formatName(p.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      ...p.types.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _typeBadge(t, small: true),
                      )),
                      if (p.takesReducedDamage) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Resists',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${p.coverageCount} SE',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullChartTab() {
    if (_selectedTypes.isEmpty) {
      return const Center(
        child: Text('Select types to see the full chart', style: TextStyle(color: Colors.white54)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All type matchups vs selected types',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...TypeEffectivenessService.allTypes.map((atkType) {
            final mult = _defensiveMatchups[atkType] ?? 1.0;
            Color bg;
            if (mult >= 4) {
              bg = Colors.red[900]!;
            } else if (mult >= 2) {
              bg = Colors.red[700]!;
            } else if (mult == 0) {
              bg = Colors.blueGrey[800]!;
            } else if (mult <= 0.25) {
              bg = Colors.green[900]!;
            } else if (mult < 1) {
              bg = Colors.green[700]!;
            } else {
              bg = Colors.grey[800]!;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  _typeBadge(atkType),
                  const Spacer(),
                  Text(
                    mult == 0 ? 'Immune' : '${mult}x',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: mult != 1.0 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _typeBadge(String type, {bool small = false}) {
    final color = AppTheme.typeColors[type] ?? Colors.grey;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: small ? 11 : 13,
        ),
      ),
    );
  }

  String _formatName(String name) {
    return name
        .split('-')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _TypeGroup {
  final String type;
  final double multiplier;
  _TypeGroup(this.type, this.multiplier);
}

class _RecommendedPokemon {
  final String name;
  final List<String> types;
  final int coverageCount;
  final bool takesReducedDamage;

  _RecommendedPokemon({
    required this.name,
    required this.types,
    required this.coverageCount,
    required this.takesReducedDamage,
  });
}
