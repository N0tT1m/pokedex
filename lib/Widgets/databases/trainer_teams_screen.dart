import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../pokemon/pokemon_detail_sheet.dart';

class TrainerTeamsScreen extends StatefulWidget {
  const TrainerTeamsScreen({Key? key}) : super(key: key);

  @override
  State<TrainerTeamsScreen> createState() => _TrainerTeamsScreenState();
}

class _TrainerTeamsScreenState extends State<TrainerTeamsScreen> {
  List<Map<String, dynamic>> _allTrainers = [];
  List<Map<String, dynamic>> _filteredTrainers = [];
  bool _isLoading = true;
  String? _error;
  List<String> _games = ['All'];
  String _selectedGame = 'All';
  String _query = '';

  // Team detail
  Map<String, dynamic>? _selectedTrainer;
  List<Map<String, dynamic>> _team = [];
  bool _isLoadingTeam = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    try {
      final r = await Requests.get('${PokeApiService.baseUrl}/trainer');
      if (r.statusCode == 200) {
        final results = List<Map<String, dynamic>>.from(r.json()['results'] ?? []);
        final gameSet = <String>{'All'};
        for (final t in results) { gameSet.add(t['game'] as String); }
        setState(() {
          _allTrainers = results;
          _filteredTrainers = results;
          _games = gameSet.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Server error ${r.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Could not load trainers'; _isLoading = false; });
    }
  }

  void _filter() {
    setState(() {
      _filteredTrainers = _allTrainers.where((t) {
        final gameMatch = _selectedGame == 'All' || t['game'] == _selectedGame;
        final queryMatch = _query.isEmpty ||
            (t['name'] as String).toLowerCase().contains(_query) ||
            ((t['location'] as String?) ?? '').toLowerCase().contains(_query) ||
            ((t['role'] as String?) ?? '').toLowerCase().contains(_query);
        return gameMatch && queryMatch;
      }).toList();
    });
  }

  Future<void> _loadTeam(Map<String, dynamic> trainer) async {
    setState(() { _selectedTrainer = trainer; _isLoadingTeam = true; _team = []; });
    try {
      final name = Uri.encodeComponent(trainer['name'] as String);
      final game = Uri.encodeComponent(trainer['game'] as String);
      final variant = Uri.encodeComponent(trainer['battle_variant'] as String? ?? '');
      final r = await Requests.get('${PokeApiService.baseUrl}/trainer/$name/team?game=$game&variant=$variant');
      if (r.statusCode == 200) {
        setState(() { _team = List<Map<String, dynamic>>.from(r.json()['results'] ?? []); _isLoadingTeam = false; });
      } else {
        setState(() => _isLoadingTeam = false);
      }
    } catch (_) {
      setState(() => _isLoadingTeam = false);
    }
  }

  String _fmt(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTrainer != null ? '${_selectedTrainer!['name']} — Team' : 'Trainer Teams'),
        backgroundColor: Colors.red,
        leading: _selectedTrainer != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() { _selectedTrainer = null; _team = []; }))
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _selectedTrainer != null
                  ? _buildTeam()
                  : _buildTrainerList(),
    );
  }

  Widget _buildTrainerList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search trainers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (v) { _query = v.toLowerCase(); _filter(); },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedGame,
                items: _games.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) { if (v != null) { _selectedGame = v; _filter(); } },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${_filteredTrainers.length} trainers', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filteredTrainers.length,
            itemBuilder: (context, i) {
              final t = _filteredTrainers[i];
              final role = t['role'] as String?;
              final type = t['specialty_type'] as String?;
              final location = t['location'] as String?;
              final variant = t['battle_variant'] as String? ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  title: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    spacing: 6,
                    children: [
                      Text(t['game'] as String, style: TextStyle(fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                      if (role != null) Text(role, style: const TextStyle(fontSize: 11)),
                      if (type != null) Text('Type: $type', style: const TextStyle(fontSize: 11)),
                      if (location != null) Text('📍 $location', style: const TextStyle(fontSize: 11)),
                      if (variant.isNotEmpty && variant != 'default') Text('($variant)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadTeam(t),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeam() {
    if (_isLoadingTeam) return const Center(child: CircularProgressIndicator());
    if (_team.isEmpty) return const Center(child: Text('No team data found'));

    final trainer = _selectedTrainer!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.red.shade50,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trainer['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${trainer['game']} — ${trainer['role'] ?? 'Trainer'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    if ((trainer['location'] as String?) != null)
                      Text('📍 ${trainer['location']}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              if ((trainer['specialty_type'] as String?) != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(trainer['specialty_type'] as String, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _team.length,
            itemBuilder: (context, i) {
              final p = _team[i];
              final pokeName = _fmt(p['pokemon_name'] as String);
              final level = p['level'] as int?;
              final heldItem = p['held_item'] as String?;
              final ability = p['ability'] as String?;
              final moves = List<String>.from(p['moves'] ?? []);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: Text('${i + 1}', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Text(pokeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (level != null) ...[
                        const SizedBox(width: 8),
                        Text('Lv. $level', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ability != null) Text('Ability: ${_fmt(ability)}', style: const TextStyle(fontSize: 12)),
                      if (heldItem != null) Text('Holds: ${_fmt(heldItem)}', style: const TextStyle(fontSize: 12)),
                      if (moves.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: moves.map((m) => Chip(
                            label: Text(_fmt(m), style: const TextStyle(fontSize: 10)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showPokemonDetailSheet(context, p['pokemon_name'] as String),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
