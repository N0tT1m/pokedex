import 'package:flutter/material.dart';
import '../../services/type_effectiveness_service.dart';
import '../../theme/app_theme.dart';

class TypeChartScreen extends StatefulWidget {
  const TypeChartScreen({Key? key}) : super(key: key);

  @override
  State<TypeChartScreen> createState() => _TypeChartScreenState();
}

class _TypeChartScreenState extends State<TypeChartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedAttackType;
  List<String> _selectedDefenseTypes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Type Chart'),
        backgroundColor: Colors.red,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Calculator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFullChart(),
          _buildCalculator(),
        ],
      ),
    );
  }

  Widget _buildFullChart() {
    final types = TypeEffectivenessService.allTypes;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('ATK \\ DEF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              Row(
                children: [
                  const SizedBox(width: 60),
                  ...types.map((t) => _typeHeader(t)),
                ],
              ),
              ...types.map((atkType) => Row(
                children: [
                  _typeLabel(atkType),
                  ...types.map((defType) {
                    final eff = TypeEffectivenessService.getEffectiveness(atkType, defType);
                    return _effectivenessCell(eff);
                  }),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeHeader(String type) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AppTheme.typeColors[type],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.substring(0, 3),
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _typeLabel(String type) {
    return Container(
      width: 60,
      height: 36,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AppTheme.typeColors[type],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.length > 6 ? type.substring(0, 6) : type,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _effectivenessCell(double eff) {
    Color bgColor;
    String label;
    if (eff == 0) {
      bgColor = Colors.black;
      label = '0';
    } else if (eff == 0.25) {
      bgColor = Colors.red.shade900;
      label = '1/4';
    } else if (eff == 0.5) {
      bgColor = Colors.red.shade400;
      label = '1/2';
    } else if (eff == 1.0) {
      bgColor = Colors.grey.shade300;
      label = '';
    } else if (eff == 2.0) {
      bgColor = Colors.green;
      label = '2';
    } else {
      bgColor = Colors.green.shade800;
      label = '4';
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: eff == 1.0 ? Colors.black54 : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCalculator() {
    final matchups = _selectedDefenseTypes.isNotEmpty
        ? TypeEffectivenessService.getDefensiveMatchups(_selectedDefenseTypes)
        : <String, double>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Defending Type(s):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TypeEffectivenessService.allTypes.map((type) {
              final isSelected = _selectedDefenseTypes.contains(type);
              return FilterChip(
                label: Text(type, style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12)),
                selected: isSelected,
                backgroundColor: AppTheme.typeColors[type]?.withValues(alpha: 0.3),
                selectedColor: AppTheme.typeColors[type],
                onSelected: (selected) {
                  setState(() {
                    if (selected && _selectedDefenseTypes.length < 2) {
                      _selectedDefenseTypes.add(type);
                    } else {
                      _selectedDefenseTypes.remove(type);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedDefenseTypes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Defending: ${_selectedDefenseTypes.join(" / ")}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildMatchupSection('Super Effective (Weak to)', matchups, (e) => e > 1.0, Colors.red),
            _buildMatchupSection('Not Very Effective (Resists)', matchups, (e) => e > 0 && e < 1.0, Colors.green),
            _buildMatchupSection('No Effect (Immune)', matchups, (e) => e == 0, Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchupSection(String title, Map<String, double> matchups, bool Function(double) filter, Color color) {
    final filtered = matchups.entries.where((e) => filter(e.value)).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filtered.map((entry) => Chip(
            avatar: CircleAvatar(
              backgroundColor: AppTheme.typeColors[entry.key],
              child: Text('${entry.value}x', style: const TextStyle(fontSize: 8, color: Colors.white)),
            ),
            label: Text(entry.key),
            backgroundColor: color.withValues(alpha: 0.1),
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
