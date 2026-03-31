import 'package:flutter/material.dart';
import '../../services/pokeapi_service.dart';

class LearnsetScreen extends StatefulWidget {
  final String? pokemonName;
  const LearnsetScreen({Key? key, this.pokemonName}) : super(key: key);

  @override
  State<LearnsetScreen> createState() => _LearnsetScreenState();
}

class _LearnsetScreenState extends State<LearnsetScreen> with SingleTickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> _movesByMethod = {};
  bool _isLoading = false;
  TabController? _tabController;
  String? _currentPokemon;
  List<String> _pokemonNames = [];
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.pokemonName != null) {
      _currentPokemon = widget.pokemonName;
      _isLoading = true;
      _loadMoves(widget.pokemonName!);
    }
    _loadPokemonList();
  }

  Future<void> _loadPokemonList() async {
    try {
      final list = await PokeApiService.getPokemonList(limit: 1025);
      setState(() {
        _pokemonNames = list.map((p) => p['name'] as String).toList();
        _isLoadingNames = false;
      });
    } catch (_) {
      setState(() => _isLoadingNames = false);
    }
  }

  // Maps API learn_method values (both DB-stored lowercase and display-capitalized) to tab keys
  static const _methodKeyMap = {
    'Level Up': 'level-up', 'level-up': 'level-up',
    'TM': 'machine',        'tm': 'machine',
    'Egg': 'egg',           'egg': 'egg',
    'Tutor': 'tutor',       'tutor': 'tutor',
  };

  Future<void> _loadMoves(String name) async {
    setState(() {
      _isLoading = true;
      _currentPokemon = name;
    });

    try {
      final moves = await PokeApiService.getPokemonMoves(name.toLowerCase());

      final byMethod = <String, List<Map<String, dynamic>>>{
        'level-up': [],
        'machine': [],
        'egg': [],
        'tutor': [],
      };

      for (var move in moves) {
        final rawMethod = move['learn_method'] as String? ?? '';
        final methodKey = _methodKeyMap[rawMethod] ?? rawMethod;
        if (!byMethod.containsKey(methodKey)) continue;

        final rawName = move['name'] as String? ?? '';
        final formattedName = rawName
            .split('-')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
            .join(' ');

        final levelOrTm = move['level_or_tm'] as String? ?? '0';
        final level = int.tryParse(levelOrTm) ?? 0;

        byMethod[methodKey]!.add({
          'name': formattedName,
          'level': level,
          'type': move['type'] as String?,
          'power': move['power'],
          'accuracy': move['accuracy'],
        });
      }

      byMethod['level-up']!.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));

      setState(() {
        _movesByMethod = byMethod;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPokemon == null) {
      return _buildSearchView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalize(_currentPokemon!)} Moves'),
        backgroundColor: Colors.red,
        leading: widget.pokemonName == null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentPokemon = null))
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(text: 'Level Up (${_movesByMethod['level-up']?.length ?? 0})'),
            Tab(text: 'TM/HM (${_movesByMethod['machine']?.length ?? 0})'),
            Tab(text: 'Egg (${_movesByMethod['egg']?.length ?? 0})'),
            Tab(text: 'Tutor (${_movesByMethod['tutor']?.length ?? 0})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMoveList('level-up', showLevel: true),
                _buildMoveList('machine'),
                _buildMoveList('egg'),
                _buildMoveList('tutor'),
              ],
            ),
    );
  }

  Widget _buildSearchView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Learnsets'), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search a Pokemon to view its learnset', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            if (_isLoadingNames)
              const Center(child: CircularProgressIndicator())
            else
              Autocomplete<String>(
                optionsBuilder: (v) {
                  if (v.text.isEmpty) return const Iterable.empty();
                  return _pokemonNames.where((n) => n.contains(v.text.toLowerCase())).take(10);
                },
                onSelected: (name) => _loadMoves(name),
                fieldViewBuilder: (ctx, ctrl, focus, submit) => TextField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: InputDecoration(
                    hintText: 'Search Pokemon...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveList(String method, {bool showLevel = false}) {
    final moves = _movesByMethod[method] ?? [];
    if (moves.isEmpty) {
      return const Center(child: Text('No moves available'));
    }

    return ListView.builder(
      itemCount: moves.length,
      itemBuilder: (context, index) {
        final move = moves[index];
        final subtitleParts = <String>[];
        if (move['type'] != null) subtitleParts.add(move['type']);
        if (move['power'] != null) subtitleParts.add('Pow: ${move['power']}');
        if (move['accuracy'] != null) subtitleParts.add('Acc: ${move['accuracy']}');
        final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(' · ') : null;

        return ListTile(
          leading: showLevel
              ? CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 16,
                  child: Text('${move['level']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                )
              : null,
          title: Text(move['name']),
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
          dense: true,
        );
      },
    );
  }

  String _capitalize(String s) => s.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
}
