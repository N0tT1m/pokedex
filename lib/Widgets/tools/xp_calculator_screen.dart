import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pokeapi_service.dart';
import '../../services/experience_service.dart';

class XPCalculatorScreen extends StatefulWidget {
  const XPCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<XPCalculatorScreen> createState() => _XPCalculatorScreenState();
}

class _XPCalculatorScreenState extends State<XPCalculatorScreen> {
  String _growthRate = 'medium-fast';
  int _currentLevel = 1;
  int _targetLevel = 100;
  String? _selectedPokemon;
  bool _showTable = false;
  List<String> _pokemonNames = [];
  bool _isLoading = true;

  final _currentCtrl = TextEditingController(text: '1');
  final _targetCtrl = TextEditingController(text: '100');

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

  Future<void> _loadPokemonGrowthRate(String name) async {
    try {
      final species = await PokeApiService.getPokemonSpecies(name.toLowerCase());
      final rate = species['growth_rate']?['name'] as String?;
      if (rate != null) {
        setState(() {
          _selectedPokemon = name;
          _growthRate = rate;
        });
      }
    } catch (_) {}
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final xpNeeded = ExperienceService.xpBetweenLevels(_growthRate, _currentLevel, _targetLevel);
    final totalXPTarget = ExperienceService.totalXPForLevel(_growthRate, _targetLevel);
    final totalXPCurrent = ExperienceService.totalXPForLevel(_growthRate, _currentLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('XP Calculator'), backgroundColor: Colors.red),
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
                          const Text('Pokemon (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            optionsBuilder: (v) {
                              if (v.text.isEmpty) return const Iterable.empty();
                              return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                            },
                            onSelected: _loadPokemonGrowthRate,
                            fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                              controller: ctrl, focusNode: focus,
                              decoration: const InputDecoration(
                                hintText: 'Auto-detect growth rate...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Growth Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _growthRate, isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: ExperienceService.allGrowthRates.map((r) =>
                              DropdownMenuItem(value: r,
                                child: Text(ExperienceService.groupDescriptions[r] ?? r,
                                  style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _growthRate = v!),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _currentCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Current Level', border: OutlineInputBorder()),
                                  onChanged: (v) => setState(() => _currentLevel = (int.tryParse(v) ?? 1).clamp(1, 100)),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _targetCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Target Level', border: OutlineInputBorder()),
                                  onChanged: (v) => setState(() => _targetLevel = (int.tryParse(v) ?? 100).clamp(1, 100)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(_formatNumber(xpNeeded),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue)),
                          const Text('XP needed', style: TextStyle(color: Colors.grey)),
                          const Divider(height: 24),
                          _row('Current total XP', _formatNumber(totalXPCurrent)),
                          _row('Target total XP', _formatNumber(totalXPTarget)),
                          _row('Growth rate', _formatName(_growthRate)),
                          if (_selectedPokemon != null)
                            _row('Pokemon', _formatName(_selectedPokemon!)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showTable = !_showTable),
                    icon: Icon(_showTable ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showTable ? 'Hide XP Table' : 'Show XP Table'),
                  ),
                  if (_showTable) ...[
                    const SizedBox(height: 8),
                    _buildXPTable(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget _buildXPTable() {
    final table = ExperienceService.getXPTable(_growthRate);
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Lv', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total XP', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('To Next', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: table.where((r) => r['level'] % 5 == 0 || r['level'] == 1).map((r) =>
            DataRow(
              color: r['level'] >= _currentLevel && r['level'] <= _targetLevel
                ? WidgetStateProperty.all(Colors.blue.withOpacity(0.1)) : null,
              cells: [
                DataCell(Text('${r['level']}')),
                DataCell(Text(_formatNumber(r['totalXP']))),
                DataCell(Text(_formatNumber(r['xpToNext']))),
              ],
            )).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }
}
