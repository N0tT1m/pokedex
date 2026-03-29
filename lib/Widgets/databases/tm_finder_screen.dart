import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class TMFinderScreen extends StatefulWidget {
  const TMFinderScreen({Key? key}) : super(key: key);

  @override
  State<TMFinderScreen> createState() => _TMFinderScreenState();
}

class _TMFinderScreenState extends State<TMFinderScreen> {
  String _selectedGame = 'scarlet-violet';
  List<Map<String, dynamic>> _tmList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = false;
  final _searchCtrl = TextEditingController();

  static const Map<String, String> _games = {
    'scarlet-violet': 'Scarlet / Violet',
    'sword-shield': 'Sword / Shield',
    'brilliant-diamond-and-shining-pearl': 'BDSP',
    'sun-moon': 'Sun / Moon',
    'x-y': 'X / Y',
    'black-white': 'Black / White',
    'diamond-pearl': 'Diamond / Pearl',
    'red-blue': 'Red / Blue',
  };

  @override
  void initState() {
    super.initState();
    _loadTMs();
  }

  Future<void> _loadTMs() async {
    setState(() => _isLoading = true);
    try {
      // Load machines list from PokeAPI
      final response = await Requests.get('${PokeApiService.baseUrl}/machine?limit=2000');
      if (response.statusCode == 200) {
        final data = response.json();
        final machines = data['results'] as List;

        // Load details for machines (in batches)
        final tmList = <Map<String, dynamic>>[];
        for (var machine in machines.take(300)) {
          try {
            final detailResponse = await Requests.get(machine['url']);
            if (detailResponse.statusCode == 200) {
              final detail = detailResponse.json();
              final versionGroup = detail['version_group']?['name'] ?? '';

              if (versionGroup == _selectedGame || _selectedGame.isEmpty) {
                final itemName = detail['item']?['name'] ?? '';
                final moveName = detail['move']?['name'] ?? '';

                tmList.add({
                  'tm': _formatTMName(itemName),
                  'move': _formatName(moveName),
                  'moveApi': moveName,
                  'game': versionGroup,
                });
              }
            }
          } catch (_) {}
        }

        // Sort by TM number
        tmList.sort((a, b) => (a['tm'] as String).compareTo(b['tm'] as String));

        setState(() {
          _tmList = tmList;
          _filteredList = tmList;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterTMs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _tmList;
      } else {
        _filteredList = _tmList.where((tm) {
          final tmName = (tm['tm'] as String).toLowerCase();
          final moveName = (tm['move'] as String).toLowerCase();
          return tmName.contains(query.toLowerCase()) || moveName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _formatTMName(String name) {
    return name.toUpperCase().replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TM / HM Finder'), backgroundColor: Colors.red),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedGame, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Game', border: OutlineInputBorder()),
              items: _games.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) {
                setState(() { _selectedGame = v!; });
                _loadTMs();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by TM number or move name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterTMs,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading TM data...', style: TextStyle(color: Colors.grey)),
              ],
            ))),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${_filteredList.length} TMs/HMs found',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (!_isLoading)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _filteredList.length,
                itemBuilder: (context, index) {
                  final tm = _filteredList[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (tm['tm'] as String).contains('HM') ? Colors.purple : Colors.blue,
                        child: Text(
                          _extractNumber(tm['tm']),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(tm['move'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tm['tm']),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _extractNumber(String tmName) {
    final match = RegExp(r'\d+').firstMatch(tmName);
    return match != null ? match.group(0)! : tmName;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
