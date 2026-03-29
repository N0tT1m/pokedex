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
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _selectedArea;
  bool _isLoading = true;
  String? _error;
  bool _isLoadingLocations = false;
  bool _isLoadingArea = false;
  String? _selectedRegionName;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/region?limit=20');
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _regions = List<Map<String, dynamic>>.from(data['results']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Could not load regions'; _isLoading = false; });
    }
  }

  Future<void> _loadRegionLocations(String url, String name) async {
    setState(() {
      _isLoadingLocations = true;
      _selectedRegionName = _formatName(name);
      _selectedArea = null;
    });

    try {
      final response = await Requests.get(url);
      if (response.statusCode == 200) {
        final data = response.json();
        setState(() {
          _locations = List<Map<String, dynamic>>.from(data['locations'] ?? []);
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _loadLocationAreas(String url) async {
    setState(() => _isLoadingArea = true);

    try {
      final response = await Requests.get(url);
      if (response.statusCode == 200) {
        final data = response.json();
        final areas = data['areas'] as List? ?? [];

        // Load encounter data for first area
        if (areas.isNotEmpty) {
          final areaResponse = await Requests.get(areas[0]['url']);
          if (areaResponse.statusCode == 200) {
            setState(() {
              _selectedArea = areaResponse.json();
              _isLoadingArea = false;
            });
            return;
          }
        }

        setState(() {
          _selectedArea = {'name': data['name'], 'pokemon_encounters': []};
          _isLoadingArea = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingArea = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedArea != null
            ? _formatName(_selectedArea!['name'] ?? '')
            : _selectedRegionName ?? 'Location Guide'),
        backgroundColor: Colors.red,
        leading: (_selectedArea != null || _selectedRegionName != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_selectedArea != null) {
                      _selectedArea = null;
                    } else {
                      _selectedRegionName = null;
                      _locations = [];
                    }
                  });
                })
            : null,
      ),
      body: _selectedArea != null
          ? _buildAreaDetail()
          : _selectedRegionName != null
              ? _buildLocationList()
              : _buildRegionList(),
    );
  }

  Widget _buildRegionList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadRegions(); }, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _regions.length,
      itemBuilder: (context, index) {
        final region = _regions[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.map, color: Colors.green),
            title: Text(_formatName(region['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadRegionLocations(region['url'], region['name']),
          ),
        );
      },
    );
  }

  Widget _buildLocationList() {
    if (_isLoadingLocations) return const Center(child: CircularProgressIndicator());

    if (_locations.isEmpty) {
      return const Center(child: Text('No locations found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final location = _locations[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: Text(_formatName(location['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadLocationAreas(location['url']),
          ),
        );
      },
    );
  }

  Widget _buildAreaDetail() {
    if (_isLoadingArea) return const Center(child: CircularProgressIndicator());

    final encounters = _selectedArea!['pokemon_encounters'] as List? ?? [];

    if (encounters.isEmpty) {
      return const Center(child: Text('No encounter data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: encounters.length,
      itemBuilder: (context, index) {
        final encounter = encounters[index];
        final pokemonName = _formatName(encounter['pokemon']['name'] ?? '');
        final versionDetails = encounter['version_details'] as List? ?? [];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => showPokemonDetailSheet(context, encounter['pokemon']['name'] ?? ''),
                  child: Row(
                    children: [
                      Expanded(child: Text(pokemonName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue))),
                      const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ...versionDetails.take(5).map((vd) {
                  final version = _formatName(vd['version']['name'] ?? '');
                  final encounterDetails = vd['encounter_details'] as List? ?? [];
                  final maxChance = vd['max_chance'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$version (${maxChance}% chance)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ...encounterDetails.take(3).map((ed) {
                          final method = _formatName(ed['method']['name'] ?? '');
                          final minLevel = ed['min_level'] ?? '?';
                          final maxLevel = ed['max_level'] ?? '?';
                          final chance = ed['chance'] ?? 0;
                          return Text('  $method: Lv.$minLevel-$maxLevel ($chance%)', style: const TextStyle(fontSize: 12));
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }
}
