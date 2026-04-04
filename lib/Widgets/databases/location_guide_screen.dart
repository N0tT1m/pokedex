import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';
import '../pokemon/pokemon_detail_sheet.dart';

class LocationGuideScreen extends StatefulWidget {
  const LocationGuideScreen({Key? key}) : super(key: key);

  @override
  State<LocationGuideScreen> createState() => _LocationGuideScreenState();
}

class _LocationGuideScreenState extends State<LocationGuideScreen> {
  List<Map<String, dynamic>> _games = [];
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _selectedArea;

  bool _isLoadingGames = true;
  bool _isLoadingRegions = false;
  bool _isLoadingLocations = false;
  bool _isLoadingArea = false;

  String? _error;
  Map<String, dynamic>? _selectedGame;
  String? _selectedRegionName;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/location/games');
      if (response.statusCode == 200) {
        final data = response.json();
        final List<dynamic> gameList = data['games'] ?? [];
        setState(() {
          _games = gameList.map((g) => {
            'abbreviation': g['abbreviation']?.toString() ?? '',
            'name': g['name']?.toString() ?? '',
          }).toList();
          _isLoadingGames = false;
        });
      } else {
        // Endpoint not deployed yet — skip game selection, go straight to regions
        setState(() { _isLoadingGames = false; });
        _loadRegions();
      }
    } catch (e) {
      setState(() { _error = 'Could not load games'; _isLoadingGames = false; });
    }
  }

  Future<void> _loadRegions() async {
    setState(() { _isLoadingRegions = true; });
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/location/regions');
      if (response.statusCode == 200) {
        final data = response.json();
        final List<dynamic> regionNames = data['regions'] ?? [];
        setState(() {
          _regions = regionNames.map((name) => {'name': name.toString()}).toList();
          _isLoadingRegions = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Could not load regions'; _isLoadingRegions = false; });
    }
  }

  Future<void> _loadRegionLocations(String regionName) async {
    setState(() {
      _isLoadingLocations = true;
      _selectedRegionName = regionName;
      _selectedArea = null;
    });

    try {
      final abbr = _selectedGame?['abbreviation'] ?? '';
      final gameParam = abbr.isNotEmpty ? '?game=${Uri.encodeComponent(abbr)}' : '';
      final response = await Requests.get(
        '${PokeApiService.baseUrl}/location/region/$regionName/routes$gameParam',
      );
      if (response.statusCode == 200) {
        final data = response.json();
        final List<dynamic> routeNames = data['routes'] ?? [];
        setState(() {
          _locations = routeNames.map((name) => {
            'name': name.toString(),
            'region': regionName,
          }).toList();
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _loadRouteEncounters(String region, String route) async {
    setState(() => _isLoadingArea = true);

    try {
      final abbr = _selectedGame?['abbreviation'] ?? '';
      final gameParam = abbr.isNotEmpty ? '?game=${Uri.encodeComponent(abbr)}' : '';
      final response = await Requests.get(
        '${PokeApiService.baseUrl}/location/region/$region/route/${Uri.encodeComponent(route)}$gameParam',
      );
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _selectedArea = {
            'name': route,
            'encounters': data['encounters'] ?? [],
          };
          _isLoadingArea = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingArea = false);
    }
  }

  String _appBarTitle() {
    if (_selectedArea != null) return _formatName(_selectedArea!['name'] ?? '');
    if (_selectedRegionName != null) return _selectedRegionName!;
    if (_selectedGame != null) return _selectedGame!['name'] ?? 'Select Region';
    return 'Location Guide';
  }

  bool _canGoBack() => _selectedArea != null || _selectedRegionName != null || _selectedGame != null;

  void _goBack() {
    setState(() {
      if (_selectedArea != null) {
        _selectedArea = null;
      } else if (_selectedRegionName != null) {
        _selectedRegionName = null;
        _locations = [];
      } else if (_selectedGame != null) {
        _selectedGame = null;
        _regions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        backgroundColor: Colors.red,
        leading: _canGoBack()
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedArea != null) return _buildAreaDetail();
    if (_selectedRegionName != null) return _buildLocationList();
    if (_selectedGame != null) return _buildRegionList();
    return _buildGameList();
  }

  Widget _buildGameList() {
    if (_isLoadingGames) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { setState(() { _isLoadingGames = true; _error = null; }); _loadGames(); },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.videogame_asset, color: Colors.red),
            title: Text(game['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(game['abbreviation'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() { _selectedGame = game; });
              _loadRegions();
            },
          ),
        );
      },
    );
  }

  Widget _buildRegionList() {
    if (_isLoadingRegions) return const Center(child: CircularProgressIndicator());

    if (_regions.isEmpty) {
      return const Center(child: Text('No regions found'));
    }

    return Column(
      children: [
        _buildGameBadge(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _regions.length,
            itemBuilder: (context, index) {
              final region = _regions[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: Text(_formatName(region['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadRegionLocations(region['name']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationList() {
    if (_isLoadingLocations) return const Center(child: CircularProgressIndicator());

    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No routes found in $_selectedRegionName\nfor ${_selectedGame?['name'] ?? 'this game'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildGameBadge(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              final location = _locations[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(_formatName(location['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadRouteEncounters(location['region'], location['name']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAreaDetail() {
    if (_isLoadingArea) return const Center(child: CircularProgressIndicator());

    final encounters = _selectedArea!['encounters'] as List? ?? [];

    if (encounters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.catching_pokemon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No encounters found\nfor ${_selectedGame?['name'] ?? 'this game'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildGameBadge(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: encounters.length,
            itemBuilder: (context, index) {
              final encounter = encounters[index];
              final pokemonName = encounter['pokemon_name'] ?? '';
              final games = List<String>.from(encounter['games'] ?? []);
              final method = encounter['encounter_method'] ?? '';
              final rarity = encounter['rarity'] ?? '';
              final levelRange = encounter['level_range'] ?? '';
              final timeOfDay = encounter['time_of_day'] ?? '';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => showPokemonDetailSheet(context, pokemonName.toLowerCase()),
                        child: Row(
                          children: [
                            Expanded(child: Text(pokemonName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue))),
                            const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (method.isNotEmpty)
                        Text('Method: $method', style: const TextStyle(fontSize: 12)),
                      if (levelRange.isNotEmpty)
                        Text('Level: $levelRange', style: const TextStyle(fontSize: 12)),
                      if (rarity.isNotEmpty)
                        Text('Rarity: $rarity', style: const TextStyle(fontSize: 12)),
                      if (timeOfDay.isNotEmpty)
                        Text('Time: $timeOfDay', style: const TextStyle(fontSize: 12)),
                      if (_selectedGame == null && games.isNotEmpty)
                        Text('Games: ${games.join(', ')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameBadge() {
    if (_selectedGame == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.videogame_asset, size: 14, color: Colors.red),
          const SizedBox(width: 6),
          Text(
            _selectedGame!['name'],
            style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }
}
