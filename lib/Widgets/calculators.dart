import 'package:flutter/material.dart';
import 'reverse_iv_calculator.dart';
import 'iv_ev_calculator.dart';

/// Combined widget for all calculators
class Calculators extends StatefulWidget {
  const Calculators({Key? key}) : super(key: key);

  @override
  State<Calculators> createState() => _CalculatorsState();
}

class _CalculatorsState extends State<Calculators> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Column(
      children: [
        Container(
          color: Colors.red,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            tabs: const [
              Tab(
                icon: Icon(Icons.functions),
                text: 'IV/EV Calc',
              ),
              Tab(
                icon: Icon(Icons.calculate),
                text: 'IV Checker',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              IVEVCalculator(),
              ReverseIVCalculator(),
            ],
          ),
        ),
      ],
    );
  }
}
