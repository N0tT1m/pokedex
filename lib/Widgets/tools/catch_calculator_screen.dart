import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pokeapi_service.dart';
import '../../services/catch_calculator_service.dart';

class CatchCalculatorScreen extends StatefulWidget {
  const CatchCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CatchCalculatorScreen> createState() => _CatchCalculatorScreenState();
}

class _CatchCalculatorScreenState extends State<CatchCalculatorScreen> {
  List<String> _pokemonNames = [];
  bool _isLoading = true;
  int _baseCatchRate = 45;
  double _hpPercent = 100;
  String _ballType = 'Poke Ball';
  String _statusCondition = 'None';
  int _level = 50;
  bool _isNight = false;
  bool _isInCave = false;
  bool _isInWater = false;
  int _turnCount = 1;
  Map<String, dynamic>? _result;
  String? _selectedPokemon;
  final _turnCtrl = TextEditingController(text: '1');
  final _levelCtrl = TextEditingController(text: '50');

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

  Future<void> _loadPokemon(String name) async {
    try {
      final species = await PokeApiService.getPokemonSpecies(name.toLowerCase());
      setState(() {
        _selectedPokemon = name;
        _baseCatchRate = species['capture_rate'] ?? 45;
      });
    } catch (_) {}
  }

  void _calculate() {
    setState(() {
      _result = CatchCalculatorService.calculateCatchRate(
        baseCatchRate: _baseCatchRate,
        hpPercent: _hpPercent,
        ballType: _ballType,
        statusCondition: _statusCondition,
        level: _level,
        isNight: _isNight,
        isInCave: _isInCave,
        isInWater: _isInWater,
        turnCount: _turnCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catch Calculator'), backgroundColor: Colors.red),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pokemon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            optionsBuilder: (v) {
                              if (v.text.isEmpty) return const Iterable.empty();
                              return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                            },
                            onSelected: _loadPokemon,
                            fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                              controller: ctrl, focusNode: focus,
                              decoration: const InputDecoration(hintText: 'Search Pokemon...', border: OutlineInputBorder()),
                            ),
                          ),
                          if (_selectedPokemon != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Base catch rate: $_baseCatchRate / 255',
                                style: const TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('HP Remaining: ${_hpPercent.toInt()}%'),
                          Slider(
                            value: _hpPercent, min: 1, max: 100, divisions: 99,
                            onChanged: (v) => setState(() => _hpPercent = v),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _levelCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                                  onChanged: (v) => _level = int.tryParse(v) ?? 50,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _turnCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Turn #', border: OutlineInputBorder()),
                                  onChanged: (v) => _turnCount = int.tryParse(v) ?? 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _ballType, isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Ball Type', border: OutlineInputBorder()),
                            items: CatchCalculatorService.allBalls.map((b) =>
                              DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (v) => setState(() => _ballType = v!),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _statusCondition, isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: CatchCalculatorService.allStatuses.map((s) =>
                              DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _statusCondition = v!),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(label: const Text('Night'), selected: _isNight,
                                onSelected: (v) => setState(() => _isNight = v)),
                              FilterChip(label: const Text('Cave'), selected: _isInCave,
                                onSelected: (v) => setState(() => _isInCave = v)),
                              FilterChip(label: const Text('Water'), selected: _isInWater,
                                onSelected: (v) => setState(() => _isInWater = v)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
                    child: const Text('Calculate', style: TextStyle(fontSize: 18, color: Colors.white)),
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

  Widget _buildResult() {
    final r = _result!;
    final prob = r['catchProbability'] as double;
    final color = prob >= 75 ? Colors.green : prob >= 30 ? Colors.orange : Colors.red;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${prob.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
            const Text('catch probability', style: TextStyle(color: Colors.grey)),
            const Divider(),
            _resultRow('Per-shake probability', '${(r['shakeProbability'] as double).toStringAsFixed(1)}%'),
            _resultRow('Ball modifier', '${r['ballModifier']}x'),
            _resultRow('Status modifier', '${r['statusModifier']}x'),
            _resultRow('Average attempts', '~${r['averageAttempts']}'),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }

  @override
  void dispose() {
    _turnCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }
}
