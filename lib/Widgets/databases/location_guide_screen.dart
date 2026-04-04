import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';
import '../pokemon/pokemon_detail_sheet.dart' show PokemonDetailPage;

class LocationGuideScreen extends StatefulWidget {
  const LocationGuideScreen({Key? key}) : super(key: key);

  @override
  State<LocationGuideScreen> createState() => _LocationGuideScreenState();
}

// Mirrors the game groups in game_version_filter.dart, mapped to location_encounters abbreviations.
const _kGameGroups = [
  {
    'generation': 'Generation I',
    'games': [
      {'name': 'Red / Blue', 'abbrs': ['R', 'B'], 'color': 0xFFE53935},
      {'name': 'Yellow', 'abbrs': ['Y'], 'color': 0xFFFDD835},
    ],
  },
  {
    'generation': 'Generation II',
    'games': [
      {'name': 'Gold / Silver', 'abbrs': ['G', 'S'], 'color': 0xFFFF8F00},
      {'name': 'Crystal', 'abbrs': ['C'], 'color': 0xFF00ACC1},
    ],
  },
  {
    'generation': 'Generation III',
    'games': [
      {'name': 'Ruby / Sapphire', 'abbrs': ['R', 'S'], 'color': 0xFFE53935},
      {'name': 'Emerald', 'abbrs': ['E'], 'color': 0xFF43A047},
      {'name': 'FireRed / LeafGreen', 'abbrs': ['FR', 'LG'], 'color': 0xFFFF7043},
    ],
  },
  {
    'generation': 'Generation IV',
    'games': [
      {'name': 'Diamond / Pearl', 'abbrs': ['D', 'P'], 'color': 0xFF1E88E5},
      {'name': 'Platinum', 'abbrs': ['Pt'], 'color': 0xFF757575},
      {'name': 'HeartGold / SoulSilver', 'abbrs': ['HG', 'SS'], 'color': 0xFFFFB300},
    ],
  },
  {
    'generation': 'Generation V',
    'games': [
      {'name': 'Black / White', 'abbrs': ['B', 'W'], 'color': 0xFF546E7A},
      {'name': 'Black 2 / White 2', 'abbrs': ['B2', 'W2'], 'color': 0xFF546E7A},
    ],
  },
  {
    'generation': 'Generation VI',
    'games': [
      {'name': 'X / Y', 'abbrs': ['X', 'Y'], 'color': 0xFF3949AB},
      {'name': 'Omega Ruby / Alpha Sapphire', 'abbrs': ['OR', 'AS'], 'color': 0xFFE53935},
    ],
  },
  {
    'generation': 'Generation VII',
    'games': [
      {'name': 'Sun / Moon', 'abbrs': ['M', 'S'], 'color': 0xFFFF8F00},
      {'name': 'Ultra Sun / Ultra Moon', 'abbrs': ['US', 'UM'], 'color': 0xFFFF7043},
      {'name': "Let's Go Pikachu / Eevee", 'abbrs': ['LGP', 'LGE'], 'color': 0xFFFDD835},
    ],
  },
  {
    'generation': 'Generation VIII',
    'games': [
      {'name': 'Sword / Shield', 'abbrs': ['Sw', 'Sh'], 'color': 0xFF1E88E5},
      {'name': 'Brilliant Diamond / Shining Pearl', 'abbrs': ['BD', 'SP'], 'color': 0xFF29B6F6},
      {'name': 'Legends: Arceus', 'abbrs': ['LA'], 'color': 0xFF00897B},
    ],
  },
  {
    'generation': 'Generation IX',
    'games': [
      {'name': 'Scarlet / Violet', 'abbrs': ['S', 'V'], 'color': 0xFF7B1FA2},
    ],
  },
];

class _LocationGuideScreenState extends State<LocationGuideScreen> {
  // Selected game from the hardcoded list
  Map<String, dynamic>? _selectedGame;

  // Encode a path segment — Uri.encodeComponent leaves ' unencoded which breaks chi routing
  String _enc(String s) => Uri.encodeComponent(s).replaceAll("'", '%27');

  // Routes grouped by region: { 'Sinnoh': ['Route 201', ...], ... }
  Map<String, List<String>> _routesByRegion = {};
  bool _isLoadingRoutes = false;

  // Selected route encounter data
  String? _selectedRoute;
  String? _selectedRouteRegion;
  List<Map<String, dynamic>> _encounters = [];
  bool _isLoadingEncounters = false;

  // Search within encounter list
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<String> get _abbrs =>
      List<String>.from((_selectedGame?['abbrs'] as List?) ?? []);

  Future<void> _loadRoutes() async {
    setState(() { _isLoadingRoutes = true; _routesByRegion = {}; });

    try {
      final regionsResp = await Requests.get('${PokeApiService.baseUrl}/location/regions');
      if (regionsResp.statusCode != 200) {
        setState(() => _isLoadingRoutes = false);
        return;
      }
      final allRegions = List<String>.from(regionsResp.json()['regions'] ?? []);

      // Parallel: fetch routes for each region × each abbr, then merge
      final futures = allRegions.map((region) async {
        final Set<String> routes = {};
        await Future.wait(_abbrs.map((abbr) async {
          try {
            final r = await Requests.get(
              '${PokeApiService.baseUrl}/location/region/${_enc(region)}/routes?game=${_enc(abbr)}',
            );
            if (r.statusCode == 200) {
              routes.addAll(List<String>.from(r.json()['routes'] ?? []));
            }
          } catch (_) {}
        }));
        return MapEntry(region, routes.toList()..sort());
      });

      final results = await Future.wait(futures);
      final Map<String, List<String>> grouped = {};
      for (final entry in results) {
        if (entry.value.isNotEmpty) grouped[entry.key] = entry.value;
      }

      setState(() { _routesByRegion = grouped; _isLoadingRoutes = false; });
    } catch (e) {
      setState(() => _isLoadingRoutes = false);
    }
  }

  Future<void> _loadEncounters(String region, String route) async {
    setState(() {
      _selectedRoute = route;
      _selectedRouteRegion = region;
      _encounters = [];
      _isLoadingEncounters = true;
    });

    try {
      // Fetch encounters for each abbr and merge (de-dup by pokemon+method)
      final Set<String> seen = {};
      final List<Map<String, dynamic>> all = [];

      await Future.wait(_abbrs.map((abbr) async {
        try {
          final r = await Requests.get(
            '${PokeApiService.baseUrl}/location/region/${_enc(region)}/route/${_enc(route)}?game=${_enc(abbr)}',
          );
          if (r.statusCode == 200) {
            final enc = List<Map<String, dynamic>>.from(r.json()['encounters'] ?? []);
            for (final e in enc) {
              final key = '${e['pokemon_name']}|${e['encounter_method']}';
              if (!seen.contains(key)) {
                seen.add(key);
                all.add(Map<String, dynamic>.from(e));
              }
            }
          }
        } catch (_) {}
      }));

      all.sort((a, b) => (a['pokemon_name'] as String).compareTo(b['pokemon_name'] as String));

      // Enrich with sprite + types in parallel (same pattern as game_version_filter)
      await Future.wait(all.map((enc) async {
        try {
          final name = (enc['pokemon_name'] as String).toLowerCase();
          final r = await Requests.get('${PokeApiService.baseUrl}/pokemon/$name');
          if (r.statusCode == 200) {
            final d = r.json();
            enc['sprite'] = d['sprites']?['other']?['official-artwork']?['front_default']
                ?? d['sprites']?['front_default']
                ?? '';
            enc['id'] = d['id'] ?? 0;
            final typeList = d['types'] as List? ?? [];
            enc['types'] = typeList.map((t) {
              final typeName = t['type']?['name'] as String? ?? '';
              return typeName[0].toUpperCase() + typeName.substring(1);
            }).toList();
          }
        } catch (_) {}
      }));

      setState(() { _encounters = all; _isLoadingEncounters = false; });
    } catch (e) {
      setState(() => _isLoadingEncounters = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    setState(() {
      if (_selectedRoute != null) {
        _selectedRoute = null;
        _selectedRouteRegion = null;
        _encounters = [];
        _searchCtrl.clear();
        _searchQuery = '';
      } else {
        _selectedGame = null;
        _routesByRegion = {};
      }
    });
  }

  String get _appBarTitle {
    if (_selectedRoute != null) return _selectedRoute!;
    if (_selectedGame != null) return _selectedGame!['name'] as String;
    return 'Location Guide';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.red,
        leading: _selectedGame != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
      ),
      body: _selectedRoute != null
          ? _buildEncounters()
          : _selectedGame != null
              ? _buildRouteList()
              : _buildGameSelector(),
    );
  }

  // ── Game selector (same pattern as game_version_filter) ───────────────────

  Widget _buildGameSelector() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _kGameGroups.length,
      itemBuilder: (context, i) {
        final group = _kGameGroups[i];
        final games = group['games'] as List;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                group['generation'] as String,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF616161)),
              ),
            ),
            ...games.map((game) {
              final color = Color(game['color'] as int);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.catching_pokemon, color: color, size: 32),
                  title: Text(game['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() => _selectedGame = Map<String, dynamic>.from(game as Map));
                    _loadRoutes();
                  },
                ),
              );
            }),
            if (i < _kGameGroups.length - 1) const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ── Route list grouped by region ─────────────────────────────────────────

  Widget _buildRouteList() {
    if (_isLoadingRoutes) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Loading routes...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_routesByRegion.isEmpty) {
      return const Center(child: Text('No routes found for this game'));
    }

    // Build flat list with region headers + route tiles
    final regions = _routesByRegion.keys.toList();
    final List<Widget> items = [];
    for (final region in regions) {
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          region,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF616161)),
        ),
      ));
      for (final route in _routesByRegion[region]!) {
        items.add(Card(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: Text(route, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadEncounters(region, route),
          ),
        ));
      }
    }

    return ListView(padding: const EdgeInsets.only(bottom: 12), children: items);
  }

  // ── Encounter list ────────────────────────────────────────────────────────

  Widget _buildEncounters() {
    if (_isLoadingEncounters) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_encounters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.catching_pokemon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No encounters found on $_selectedRoute\nfor ${_selectedGame?['name'] ?? 'this game'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? _encounters
        : _encounters.where((e) => (e['pokemon_name'] as String).toLowerCase().contains(_searchQuery)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search Pokemon...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() { _searchCtrl.clear(); _searchQuery = ''; }),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        if (filtered.isEmpty)
          const Expanded(child: Center(child: Text('No Pokemon match your search', style: TextStyle(color: Colors.grey)))),
        if (filtered.isNotEmpty)
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final enc = filtered[index];
        final pokemonName = enc['pokemon_name'] as String? ?? '';
        final method = enc['encounter_method'] as String? ?? '';
        final rarity = enc['rarity'] as String? ?? '';
        final levelRange = enc['level_range'] as String? ?? '';
        final timeOfDay = enc['time_of_day'] as String? ?? '';
        final sprite = enc['sprite'] as String? ?? '';
        final id = enc['id'] as int? ?? 0;
        final types = List<String>.from(enc['types'] as List? ?? []);

        final details = [
          if (method.isNotEmpty) method,
          if (levelRange.isNotEmpty) 'Lv $levelRange',
          if (rarity.isNotEmpty) rarity,
          if (timeOfDay.isNotEmpty) timeOfDay,
        ].join(' · ');

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: SizedBox(
              width: 56,
              height: 56,
              child: sprite.isNotEmpty
                  ? Image.network(
                      sprite,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 40),
                    )
                  : const Icon(Icons.catching_pokemon, size: 40),
            ),
            title: Row(
              children: [
                Text(pokemonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ...types.map((t) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.typeColors[t] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (id > 0)
                  Text('#${id.toString().padLeft(4, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (details.isNotEmpty)
                  Text(details, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PokemonDetailPage(pokemonName: pokemonName.toLowerCase())),
            ),
          ),
        );
      },
        )),
      ],
    );
  }
}
