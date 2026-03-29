import 'package:flutter/material.dart';
import '../../services/iv_calculator_service.dart';

class NatureChartScreen extends StatelessWidget {
  const NatureChartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nature Chart'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Natures affect stats by +10% / -10%',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataTable(
              columnSpacing: 16,
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 36,
              columns: const [
                DataColumn(label: Text('Nature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('+10%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green))),
                DataColumn(label: Text('-10%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red))),
              ],
              rows: IVCalculatorService.allNatures.map((nature) {
                final mods = IVCalculatorService.getNatureModifiers(nature);
                String increased = '-';
                String decreased = '-';

                for (var entry in mods.entries) {
                  if (entry.value > 1.0) increased = entry.key;
                  if (entry.value < 1.0) decreased = entry.key;
                }

                final isNeutral = increased == '-';

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    return isNeutral ? Colors.grey.withValues(alpha: 0.1) : null;
                  }),
                  cells: [
                    DataCell(Text(nature, style: TextStyle(
                      fontWeight: isNeutral ? FontWeight.normal : FontWeight.bold,
                      fontSize: 13,
                    ))),
                    DataCell(Text(increased, style: TextStyle(
                      color: increased != '-' ? Colors.green : Colors.grey,
                      fontSize: 13,
                    ))),
                    DataCell(Text(decreased, style: TextStyle(
                      color: decreased != '-' ? Colors.red : Colors.grey,
                      fontSize: 13,
                    ))),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Quick Reference', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Physical Attackers: Adamant (+Atk/-SpA) or Jolly (+Spe/-SpA)', style: TextStyle(fontSize: 12)),
                    Text('Special Attackers: Modest (+SpA/-Atk) or Timid (+Spe/-Atk)', style: TextStyle(fontSize: 12)),
                    Text('Physical Walls: Impish (+Def/-SpA) or Bold (+Def/-Atk)', style: TextStyle(fontSize: 12)),
                    Text('Special Walls: Careful (+SpD/-SpA) or Calm (+SpD/-Atk)', style: TextStyle(fontSize: 12)),
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
