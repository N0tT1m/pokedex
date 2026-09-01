import 'package:flutter/material.dart';
import '../../services/shiny_calculator_service.dart';

class ShinyCalculatorScreen extends StatefulWidget {
  const ShinyCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<ShinyCalculatorScreen> createState() => _ShinyCalculatorScreenState();
}

class _ShinyCalculatorScreenState extends State<ShinyCalculatorScreen> {
  String _selectedGame = 'Scarlet/Violet';
  String _selectedMethod = 'Full Odds';
  bool _hasShinyCharm = false;
  int _chainLength = 0;
  int _koCount = 0;
  int _dexNavLevel = 0;
  int _sandwichPower = 0;
  Map<String, dynamic>? _result;

  List<String> get _availableMethods {
    return ShinyCalculatorService.methodsByGame[_selectedGame] ?? ['Full Odds'];
  }

  int get _generation {
    if (_selectedGame.contains('Scarlet') || _selectedGame.contains('Legends')) return 9;
    if (_selectedGame.contains('Sword') || _selectedGame.contains('Brilliant')) return 8;
    if (_selectedGame.contains('Let\'s Go')) return 7;
    if (_selectedGame.contains('Sun') || _selectedGame.contains('Ultra')) return 7;
    if (_selectedGame.contains('X/Y') || _selectedGame.contains('Omega')) return 6;
    if (_selectedGame.contains('Black')) return 5;
    if (_selectedGame.contains('Diamond') || _selectedGame.contains('Heart')) return 4;
    if (_selectedGame.contains('Ruby') || _selectedGame.contains('Fire')) return 3;
    if (_selectedGame.contains('Gold')) return 2;
    return 1;
  }

  void _calculate() {
    setState(() {
      _result = ShinyCalculatorService.calculateOdds(
        method: _selectedMethod,
        generation: _generation,
        chainLength: _chainLength,
        hasShinyCharm: _hasShinyCharm,
        dexNavSearchLevel: _dexNavLevel,
        koCount: _koCount,
        sandwichPower: _sandwichPower,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shiny Calculator'), backgroundColor: Colors.red),
      body: SingleChildScrollView(
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
                    const Text('Game', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGame, isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ShinyCalculatorService.methodsByGame.keys.map((g) =>
                        DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedGame = v!;
                          if (!_availableMethods.contains(_selectedMethod)) {
                            _selectedMethod = _availableMethods.first;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMethod, isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _availableMethods.map((m) =>
                        DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _selectedMethod = v!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Shiny Charm'),
                      subtitle: const Text('+2 extra rolls'),
                      value: _hasShinyCharm,
                      onChanged: _generation >= 5 ? (v) => setState(() => _hasShinyCharm = v) : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_needsChainInput) Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_chainLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _chainLength.toDouble(),
                      min: 0, max: _chainMax.toDouble(),
                      divisions: _chainMax,
                      label: '$_chainLength',
                      onChanged: (v) => setState(() => _chainLength = v.toInt()),
                    ),
                    Center(child: Text('$_chainLength', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            if (_selectedMethod == 'KO Method (Sw/Sh)') Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pokemon KO\'d', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _koCount.toDouble(), min: 0, max: 500,
                      divisions: 50, label: '$_koCount',
                      onChanged: (v) => setState(() => _koCount = v.toInt()),
                    ),
                    Center(child: Text('$_koCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            if (_selectedMethod == 'DexNav') Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DexNav Search Level', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _dexNavLevel.toDouble(), min: 0, max: 999,
                      divisions: 100, label: '$_dexNavLevel',
                      onChanged: (v) => setState(() => _dexNavLevel = v.toInt()),
                    ),
                    Center(child: Text('$_dexNavLevel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            if (_selectedMethod == 'Sandwich Power (SV)') Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sparkling Power Level', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _sandwichPower.toDouble(), min: 0, max: 3,
                      divisions: 3, label: 'Lv $_sandwichPower',
                      onChanged: (v) => setState(() => _sandwichPower = v.toInt()),
                    ),
                    Center(child: Text('Level $_sandwichPower', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, padding: const EdgeInsets.all(16)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Calculate Odds', style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
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

  bool get _needsChainInput {
    return ['Chain Fishing', 'PokeRadar', 'SOS Chaining', 'Catch Combo (LGPE)'].contains(_selectedMethod);
  }

  String get _chainLabel {
    switch (_selectedMethod) {
      case 'Chain Fishing': return 'Chain Length';
      case 'PokeRadar': return 'Chain Length';
      case 'SOS Chaining': return 'SOS Chain';
      case 'Catch Combo (LGPE)': return 'Catch Combo';
      default: return 'Chain';
    }
  }

  int get _chainMax {
    switch (_selectedMethod) {
      case 'Chain Fishing': return 20;
      case 'PokeRadar': return 40;
      case 'SOS Chaining': return 40;
      case 'Catch Combo (LGPE)': return 31;
      default: return 40;
    }
  }

  Widget _buildResult() {
    final r = _result!;
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 40),
            const SizedBox(height: 8),
            Text(r['odds'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text('${(r['probability'] as double).toStringAsFixed(4)}% per encounter',
              style: const TextStyle(color: Colors.grey)),
            const Divider(height: 24),
            _statRow('50% chance by', '${r['encountersFor50']} encounters'),
            _statRow('90% chance by', '${r['encountersFor90']} encounters'),
            _statRow('99% chance by', '${r['encountersFor99']} encounters'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
