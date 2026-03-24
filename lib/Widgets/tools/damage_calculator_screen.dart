import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pokeapi_service.dart';
import '../../services/damage_calculator_service.dart';
import '../../services/iv_calculator_service.dart';
import '../../services/type_effectiveness_service.dart';
import '../../theme/app_theme.dart';

class DamageCalculatorScreen extends StatefulWidget {
  const DamageCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<DamageCalculatorScreen> createState() => _DamageCalculatorScreenState();
}

class _DamageCalculatorScreenState extends State<DamageCalculatorScreen> {
  // Attacker
  String? _attackerName;
  Map<String, dynamic>? _attackerData;
  final _atkLevelCtrl = TextEditingController(text: '50');
  String _atkNature = 'Adamant';

  // Defender
  String? _defenderName;
  Map<String, dynamic>? _defenderData;
  final _defLevelCtrl = TextEditingController(text: '50');
  String _defNature = 'Bold';

  // Move
  int _movePower = 80;
  String _moveType = 'Normal';
  String _moveCategory = 'physical';
  final _movePowerCtrl = TextEditingController(text: '80');

  // Options
  bool _isCritical = false;
  bool _isBurned = false;
  double _weatherMod = 1.0;

  // Result
  Map<String, dynamic>? _result;

  List<String> _pokemonNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPokemonList();
  }

  Future<void> _loadPokemonList() async {
    try {
      final list = await PokeApiService.getPokemonList(limit: 1025);
      setState(() {
        _pokemonNames = list.map((p) => p['name'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPokemon(String name, bool isAttacker) async {
    try {
      final data = await PokeApiService.getPokemon(name.toLowerCase());
      setState(() {
        if (isAttacker) {
          _attackerData = data;
          _attackerName = name;
        } else {
          _defenderData = data;
          _defenderName = name;
        }
      });
    } catch (_) {}
  }

  void _calculate() {
    if (_attackerData == null || _defenderData == null) return;

    final atkStats = _extractStats(_attackerData!);
    final defStats = _extractStats(_defenderData!);
    final atkTypes = _extractTypes(_attackerData!);
    final defTypes = _extractTypes(_defenderData!);

    final atkLevel = int.tryParse(_atkLevelCtrl.text) ?? 50;
    final defLevel = int.tryParse(_defLevelCtrl.text) ?? 50;

    // Calculate attack stat based on move category
    final atkNatureMods = IVCalculatorService.getNatureModifiers(_atkNature);
    final defNatureMods = IVCalculatorService.getNatureModifiers(_defNature);

    int atkStat, defStat;
    if (_moveCategory == 'physical') {
      atkStat = IVCalculatorService.calculateSingleStat(
          baseStat: atkStats['Attack']!, iv: 31, ev: 252, level: atkLevel,
          natureModifier: atkNatureMods['Attack']!, isHP: false);
      defStat = IVCalculatorService.calculateSingleStat(
          baseStat: defStats['Defense']!, iv: 31, ev: 252, level: defLevel,
          natureModifier: defNatureMods['Defense']!, isHP: false);
    } else {
      atkStat = IVCalculatorService.calculateSingleStat(
          baseStat: atkStats['Sp. Atk']!, iv: 31, ev: 252, level: atkLevel,
          natureModifier: atkNatureMods['Sp. Atk']!, isHP: false);
      defStat = IVCalculatorService.calculateSingleStat(
          baseStat: defStats['Sp. Def']!, iv: 31, ev: 252, level: defLevel,
          natureModifier: defNatureMods['Sp. Def']!, isHP: false);
    }

    final defHP = IVCalculatorService.calculateSingleStat(
        baseStat: defStats['HP']!, iv: 31, ev: 252, level: defLevel,
        natureModifier: 1.0, isHP: true);

    setState(() {
      _result = DamageCalculatorService.calculateDamage(
        level: atkLevel,
        attackStat: atkStat,
        defenseStat: defStat,
        movePower: _movePower,
        moveType: _moveType,
        moveCategory: _moveCategory,
        attackerTypes: atkTypes,
        defenderTypes: defTypes,
        defenderHP: defHP,
        isCritical: _isCritical,
        isBurned: _isBurned,
        weatherMod: _weatherMod,
      );
    });
  }

  Map<String, int> _extractStats(Map<String, dynamic> data) {
    final statMap = {'hp': 'HP', 'attack': 'Attack', 'defense': 'Defense',
        'special-attack': 'Sp. Atk', 'special-defense': 'Sp. Def', 'speed': 'Speed'};
    final stats = <String, int>{};
    for (var s in data['stats']) {
      final mapped = statMap[s['stat']['name']];
      if (mapped != null) stats[mapped] = s['base_stat'];
    }
    return stats;
  }

  List<String> _extractTypes(Map<String, dynamic> data) {
    return (data['types'] as List).map((t) {
      final name = t['type']['name'] as String;
      return name[0].toUpperCase() + name.substring(1);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Damage Calculator'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPokemonSelector('Attacker', _attackerName, _attackerData, true),
                  if (_attackerData != null) _buildLevelNature(_atkLevelCtrl, _atkNature, (v) => setState(() => _atkNature = v)),
                  const SizedBox(height: 16),
                  _buildPokemonSelector('Defender', _defenderName, _defenderData, false),
                  if (_defenderData != null) _buildLevelNature(_defLevelCtrl, _defNature, (v) => setState(() => _defNature = v)),
                  const SizedBox(height: 16),
                  _buildMoveInput(),
                  const SizedBox(height: 16),
                  _buildOptions(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
                    child: const Text('Calculate Damage', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _buildResult(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPokemonSelector(String label, String? selected, Map<String, dynamic>? data, bool isAttacker) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (v) {
                if (v.text.isEmpty) return const Iterable.empty();
                return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
              },
              onSelected: (v) => _loadPokemon(v, isAttacker),
              fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                controller: ctrl, focusNode: focus,
                decoration: InputDecoration(hintText: 'Search $label...', border: const OutlineInputBorder()),
              ),
            ),
            if (data != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ..._extractTypes(data).map((t) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.typeColors[t], borderRadius: BorderRadius.circular(8)),
                    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelNature(TextEditingController levelCtrl, String nature, Function(String) onNatureChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: levelCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: nature, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Nature', border: OutlineInputBorder()),
              items: IVCalculatorService.allNatures.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => onNatureChanged(v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Move', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _movePowerCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Power', border: OutlineInputBorder()),
                    onChanged: (v) => _movePower = int.tryParse(v) ?? 80,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _moveCategory, isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: ['physical', 'special'].map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                    onChanged: (v) => setState(() => _moveCategory = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _moveType, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: TypeEffectivenessService.allTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _moveType = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SwitchListTile(title: const Text('Critical Hit'), value: _isCritical, onChanged: (v) => setState(() => _isCritical = v)),
            SwitchListTile(title: const Text('Burned (Attacker)'), value: _isBurned, onChanged: (v) => setState(() => _isBurned = v)),
            Row(
              children: [
                const Text('  Weather: '),
                ChoiceChip(label: const Text('None'), selected: _weatherMod == 1.0, onSelected: (_) => setState(() => _weatherMod = 1.0)),
                const SizedBox(width: 4),
                ChoiceChip(label: const Text('Boost'), selected: _weatherMod == 1.5, onSelected: (_) => setState(() => _weatherMod = 1.5)),
                const SizedBox(width: 4),
                ChoiceChip(label: const Text('Weaken'), selected: _weatherMod == 0.5, onSelected: (_) => setState(() => _weatherMod = 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final typeEff = r['typeEffect'] as double;
    final effLabel = DamageCalculatorService.getEffectivenessLabel(typeEff);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(r['hits'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${r['min']} - ${r['max']} damage', style: const TextStyle(fontSize: 18)),
            Text('${(r['minPercent'] as double).toStringAsFixed(1)}% - ${(r['maxPercent'] as double).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(effLabel, style: TextStyle(
              color: typeEff > 1 ? Colors.red : typeEff < 1 ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold)),
            if (r['stab'] == true) const Text('STAB applied', style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _atkLevelCtrl.dispose();
    _defLevelCtrl.dispose();
    _movePowerCtrl.dispose();
    super.dispose();
  }
}
