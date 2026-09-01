import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../data/tm_data.dart';
import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';

const _kFallbackGames = [
  'scarlet-violet',
  'sword-shield',
  'sun-moon',
  'x-y',
  'black-white',
  'diamond-pearl',
  'ruby-sapphire',
  'fire-red-leaf-green',
  'heart-gold-soul-silver',
];

class TMFinderScreen extends StatefulWidget {
  const TMFinderScreen({Key? key}) : super(key: key);

  @override
  State<TMFinderScreen> createState() => _TMFinderScreenState();
}

class _TMFinderScreenState extends State<TMFinderScreen> {
  // TM list (loaded from /tm endpoint or fallback /move endpoint)
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  bool _usingFallback = false;

  // Game selector - loaded from API
  List<String> _games = _kFallbackGames;
  String _selectedGame = _kFallbackGames.first;

  // Search
  final _searchCtrl = TextEditingController();

  // Move detail view
  Map<String, dynamic>? _selectedMove;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadGamesAndTMs();
  }

  Future<void> _loadGamesAndTMs() async {
    // Load games first so we have correct DB game names before querying TMs
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/tm/games');
      if (response.statusCode == 200) {
        final data = response.json();
        final games = List<String>.from(data['games'] ?? []);
        if (games.isNotEmpty && mounted) {
          setState(() {
            _games = games;
            if (!games.contains(_selectedGame)) {
              _selectedGame = games.first;
            }
          });
        }
      }
    } catch (_) {
      // Keep fallback games list
    }
    _loadTMs();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadTMs() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _usingFallback = false;
      _searchCtrl.clear();
    });

    // Try the new /tm endpoint first.
    try {
      final url = '${PokeApiService.baseUrl}/tm?game=$_selectedGame';
      final response = await Requests.get(url);
      if (response.statusCode == 200) {
        final data = response.json();
        final rawList = data is Map ? data['results'] : data;
        if (rawList is List && rawList.isNotEmpty) {
          final gameData = kTmMoveData[_selectedGame] ?? {};
          final items = List<Map<String, dynamic>>.from(rawList).map((m) {
            // Strip any leading letters from tm_number to get a clean padded key e.g. "TM001"
            final rawNum = (m['tm_number'] as String? ?? '');
            final prefix = rawNum.replaceAll(RegExp(r'[0-9]'), '');  // "TM" or "HM"
            final digits = rawNum.replaceAll(RegExp(r'[^0-9]'), '');
            final tmKey = '${prefix}${digits.padLeft(3, '0')}';

            // Backend move_name is often empty — fall back to static lookup
            var moveName = (m['move_name'] as String? ?? '').toLowerCase().replaceAll(' ', '-');
            if (moveName.isEmpty) {
              moveName = gameData[tmKey] ?? '';
            }

            return {
              'tmNumber': tmKey,
              'moveName': moveName,
              'displayName': moveName.isNotEmpty ? _formatName(moveName) : tmKey,
              'game': m['game'] ?? _selectedGame,
              'location': m['location'] ?? '',
              'url': '${PokeApiService.baseUrl}/move/$moveName',
            };
          }).toList();
          setState(() {
            _allItems = items;
            _filteredItems = items;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // fall through to fallback
    }

    // Fallback: load all moves from /move endpoint.
    await _loadMoveFallback();
  }

  Future<void> _loadMoveFallback() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/move?limit=1000');
      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results']);
        final items = results.map((m) {
          final name = m['name'] as String;
          return {
            'tmNumber': null,
            'moveName': name,
            'displayName': _formatName(name),
            'game': null,
            'location': null,
            'url': m['url'],
          };
        }).toList();
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _usingFallback = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load moves';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoveDetail(String name) async {
    setState(() => _isLoadingDetail = true);
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/move/$name');
      if (response.statusCode == 200) {
        setState(() {
          _selectedMove = response.json();
          _isLoadingDetail = false;
        });
      } else {
        setState(() => _isLoadingDetail = false);
      }
    } catch (e) {
      setState(() => _isLoadingDetail = false);
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────────

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        final q = query.toLowerCase();
        _filteredItems = _allItems.where((m) {
          final name = (m['displayName'] as String).toLowerCase();
          final location = ((m['location'] ?? '') as String).toLowerCase();
          return name.contains(q) || location.contains(q);
        }).toList();
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatName(String name) {
    // Handle both hyphenated slugs (e.g. "black-white") and already-formatted names (e.g. "Black/White")
    return name
        .split('-')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TM / HM Finder'),
        backgroundColor: Colors.red,
        actions: [
          if (_selectedMove != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedMove = null),
            ),
        ],
      ),
      body: _selectedMove != null ? _buildMoveDetail() : _buildTMList(),
    );
  }

  Widget _buildTMList() {
    return Column(
      children: [
        // Game dropdown (only shown when not in fallback mode)
        _buildGameDropdown(),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search by move name or location...',
              hintStyle: const TextStyle(color: Colors.black45),
              prefixIcon: const Icon(Icons.search, color: Colors.black45),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _filterItems,
          ),
        ),

        // Status bar
        if (!_isLoading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${_filteredItems.length} ${_usingFallback ? "moves" : "TMs"} found',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (_usingFallback) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'TM data unavailable for this game — showing all moves',
                    child: Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

        // List / loading / error
        Expanded(child: _buildListBody()),
      ],
    );
  }

  Widget _buildGameDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Game',
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGame,
            isDense: true,
            isExpanded: true,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            dropdownColor: Colors.white,
            items: _games
                .map((g) => DropdownMenuItem(value: g, child: Text(_formatName(g), style: const TextStyle(color: Colors.black87))))
                .toList(),
            onChanged: (value) {
              if (value != null && value != _selectedGame) {
                setState(() => _selectedGame = value);
                _loadTMs();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
              onPressed: _loadTMs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        // tmNumber is already normalized e.g. "TM001" or "HM001"
        final tmLabel = item['tmNumber'] as String? ?? '';
        final location = (item['location'] as String? ?? '').trim();
        final moveName = item['moveName'] as String? ?? '';
        final hasMoveDetail = moveName.isNotEmpty;
        final isHM = tmLabel.startsWith('HM');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isHM ? Colors.blue : Colors.red,
              child: Text(
                isHM ? 'HM' : 'TM',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                if (tmLabel.isNotEmpty) ...[
                  Text(
                    '$tmLabel ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isHM ? Colors.blue : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    item['displayName'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: location.isNotEmpty
                ? Text(
                    location,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: hasMoveDetail ? const Icon(Icons.chevron_right) : null,
            dense: true,
            onTap: hasMoveDetail ? () => _loadMoveDetail(moveName) : null,
          ),
        );
      },
    );
  }

  // ── Move detail ───────────────────────────────────────────────────────────────

  Widget _buildMoveDetail() {
    if (_isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final move = _selectedMove!;
    final name = _formatName(move['name'] as String);
    final type = move['type']?['name'] ?? 'unknown';
    final typeCap = type[0].toUpperCase() + type.substring(1);
    final category = move['damage_class']?['name'] ?? 'status';
    final power = move['power'];
    final accuracy = move['accuracy'];
    final pp = move['pp'];
    final effectEntries = move['effect_entries'] as List? ?? [];
    String effect = '';
    for (var entry in effectEntries) {
      if (entry['language']['name'] == 'en') {
        effect = entry['short_effect'] ?? entry['effect'] ?? '';
        break;
      }
    }
    final effectChance = move['effect_chance'];
    if (effectChance != null) {
      effect = effect.replaceAll('\$effect_chance', effectChance.toString());
    }

    final flavorEntries = move['flavor_text_entries'] as List? ?? [];
    String flavorText = '';
    for (var entry in flavorEntries.reversed) {
      if (entry['language']['name'] == 'en') {
        flavorText = (entry['flavor_text'] as String).replaceAll('\n', ' ');
        break;
      }
    }

    final learnedBy = move['learned_by_pokemon'] as List? ?? [];
    final machines = move['machines'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.typeColors[typeCap] ?? Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(typeCap,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: category == 'physical'
                              ? Colors.orange
                              : category == 'special'
                                  ? Colors.blue
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn('Power', power?.toString() ?? '-'),
                      _statColumn('Accuracy', accuracy != null ? '$accuracy%' : '-'),
                      _statColumn('PP', pp?.toString() ?? '-'),
                      _statColumn('Priority', move['priority']?.toString() ?? '0'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Effect
          if (effect.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Effect',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(effect),
                    if (flavorText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(flavorText,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
          // TM/HM info
          if (machines.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TM/HM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...machines.take(10).map((m) {
                      final version = m['version_group']?['name'] ?? '';
                      return Text(
                        _formatName(version),
                        style: const TextStyle(fontSize: 12),
                      );
                    }),
                    if (machines.length > 10) Text('...and ${machines.length - 10} more'),
                  ],
                ),
              ),
            ),
          // Learned by Pokemon
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learned by ${learnedBy.length} Pokemon',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: learnedBy.map((p) {
                      final rawName = (p['pokemon']?['name'] ?? p['name'] ?? '') as String;
                      final pName = _formatName(rawName);
                      return Chip(
                        label: Text(pName, style: const TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
