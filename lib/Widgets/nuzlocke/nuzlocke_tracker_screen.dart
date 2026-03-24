import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../models/nuzlocke_run.dart';

class NuzlockeTrackerScreen extends StatefulWidget {
  const NuzlockeTrackerScreen({Key? key}) : super(key: key);

  @override
  State<NuzlockeTrackerScreen> createState() => _NuzlockeTrackerScreenState();
}

class _NuzlockeTrackerScreenState extends State<NuzlockeTrackerScreen> {
  Box<NuzlockeRun>? _box;
  NuzlockeRun? _selectedRun;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox<NuzlockeRun>('nuzlocke_runs');
    setState(() {});
  }

  List<NuzlockeRun> get _runs => _box?.values.toList() ?? [];

  Future<void> _createRun() async {
    final nameCtrl = TextEditingController();
    final gameCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Nuzlocke Run'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Run Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: gameCtrl, decoration: const InputDecoration(labelText: 'Game', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (result == true && nameCtrl.text.isNotEmpty) {
      final run = NuzlockeRun(
        id: const Uuid().v4(),
        name: nameCtrl.text,
        gameName: gameCtrl.text.isNotEmpty ? gameCtrl.text : 'Unknown',
        rules: ['First encounter per route only', 'Fainted = dead', 'Must nickname all Pokemon'],
        startDate: DateTime.now(),
      );
      await _box!.put(run.id, run);
      setState(() {});
    }
  }

  Future<void> _addEncounter(NuzlockeRun run) async {
    final pokemonCtrl = TextEditingController();
    final nicknameCtrl = TextEditingController();
    final routeCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Encounter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Route/Location', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: pokemonCtrl, decoration: const InputDecoration(labelText: 'Pokemon', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: nicknameCtrl, decoration: const InputDecoration(labelText: 'Nickname', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (result == true && pokemonCtrl.text.isNotEmpty) {
      run.encounters.add(NuzlockeEncounter(
        pokemonName: pokemonCtrl.text,
        nickname: nicknameCtrl.text.isNotEmpty ? nicknameCtrl.text : null,
        routeName: routeCtrl.text.isNotEmpty ? routeCtrl.text : 'Unknown',
      ));
      await _box!.put(run.id, run);
      setState(() {});
    }
  }

  void _toggleStatus(NuzlockeRun run, int index) {
    final e = run.encounters[index];
    final statuses = ['alive', 'boxed', 'dead'];
    final currentIdx = statuses.indexOf(e.status);
    e.status = statuses[(currentIdx + 1) % 3];
    _box!.put(run.id, run);
    setState(() {});
  }

  void _toggleParty(NuzlockeRun run, int index) {
    run.encounters[index].inParty = !run.encounters[index].inParty;
    _box!.put(run.id, run);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedRun != null ? _selectedRun!.name : 'Nuzlocke Tracker'),
        backgroundColor: Colors.red,
        leading: _selectedRun != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedRun = null))
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
        onPressed: _selectedRun != null ? () => _addEncounter(_selectedRun!) : _createRun,
      ),
      body: _box == null
          ? const Center(child: CircularProgressIndicator())
          : _selectedRun != null
              ? _buildRunDetail()
              : _buildRunList(),
    );
  }

  Widget _buildRunList() {
    final runs = _runs;
    if (runs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.catching_pokemon, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Nuzlocke runs yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Tap + to start one!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: runs.length,
      itemBuilder: (context, index) {
        final run = runs[index];
        return Card(
          child: ListTile(
            title: Text(run.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${run.gameName} | ${run.aliveCount} alive | ${run.deadCount} dead'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (run.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => setState(() => _selectedRun = run),
          ),
        );
      },
    );
  }

  Widget _buildRunDetail() {
    final run = _selectedRun!;
    final party = run.encounters.where((e) => e.status == 'alive' && e.inParty).toList();
    final alive = run.encounters.where((e) => e.status == 'alive' && !e.inParty).toList();
    final boxed = run.encounters.where((e) => e.status == 'boxed').toList();
    final dead = run.encounters.where((e) => e.status == 'dead').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBadge('Party', party.length, Colors.blue),
                  _statBadge('Boxed', boxed.length, Colors.orange),
                  _statBadge('Dead', dead.length, Colors.red),
                  _statBadge('Total', run.encounters.length, Colors.grey),
                ],
              ),
            ),
          ),
          if (party.isNotEmpty) _buildSection('Party', party, run, Colors.blue),
          if (alive.isNotEmpty) _buildSection('Alive (not in party)', alive, run, Colors.green),
          if (boxed.isNotEmpty) _buildSection('Boxed', boxed, run, Colors.orange),
          if (dead.isNotEmpty) _buildSection('Cemetery', dead, run, Colors.red),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: color, radius: 18,
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildSection(String title, List<NuzlockeEncounter> encounters, NuzlockeRun run, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ...encounters.map((e) {
          final idx = run.encounters.indexOf(e);
          return Card(
            child: ListTile(
              title: Text(e.nickname ?? e.pokemonName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.pokemonName} | ${e.routeName}'),
              leading: Icon(
                e.status == 'dead' ? Icons.close : e.status == 'boxed' ? Icons.inventory : Icons.catching_pokemon,
                color: e.status == 'dead' ? Colors.red : e.status == 'boxed' ? Colors.orange : Colors.green,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.status == 'alive')
                    IconButton(
                      icon: Icon(e.inParty ? Icons.star : Icons.star_border, color: e.inParty ? Colors.amber : null),
                      onPressed: () => _toggleParty(run, idx),
                      tooltip: 'Toggle party',
                    ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    onPressed: () => _toggleStatus(run, idx),
                    tooltip: 'Change status',
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
