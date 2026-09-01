import 'package:flutter/material.dart';
import '../services/pokemondb_service.dart';
import '../services/pokeapi_service.dart';

// ---------------------------------------------------------------------------
// Type → colour mapping for tera badge
// ---------------------------------------------------------------------------
const Map<String, Color> _typeColors = {
  'Normal':   Color(0xFFA8A878),
  'Fire':     Color(0xFFF08030),
  'Water':    Color(0xFF6890F0),
  'Electric': Color(0xFFF8D030),
  'Grass':    Color(0xFF78C850),
  'Ice':      Color(0xFF98D8D8),
  'Fighting': Color(0xFFC03028),
  'Poison':   Color(0xFFA040A0),
  'Ground':   Color(0xFFE0C068),
  'Flying':   Color(0xFFA890F0),
  'Psychic':  Color(0xFFF85888),
  'Bug':      Color(0xFFA8B820),
  'Rock':     Color(0xFFB8A038),
  'Ghost':    Color(0xFF705898),
  'Dragon':   Color(0xFF7038F8),
  'Dark':     Color(0xFF705848),
  'Steel':    Color(0xFFB8B8D0),
  'Fairy':    Color(0xFFEE99AC),
};

Color _typeColor(String? type) =>
    _typeColors[type ?? ''] ?? const Color(0xFF888888);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _displayName(String raw) =>
    raw.split('-').map(_capitalize).join(' ');

// ---------------------------------------------------------------------------
// News widget
// ---------------------------------------------------------------------------
class News extends StatefulWidget {
  const News({Key? key}) : super(key: key);

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _activeFuture;
  late Future<List<Map<String, dynamic>>> _allFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activeFuture = PokemonDBService.getActiveRaids();
    _allFuture   = PokemonDBService.getRaidEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    PokemonDBService.clearRaidCache();
    setState(() {
      _activeFuture = PokemonDBService.getActiveRaids();
      _allFuture    = PokemonDBService.getRaidEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tera Raid Events'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active Now'),
            Tab(text: 'All Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RaidList(future: _activeFuture, onRefresh: _refresh, emptyMessage: 'No active Tera Raid events right now.\nCheck back when a new event starts!'),
          _RaidList(future: _allFuture,    onRefresh: _refresh, emptyMessage: 'No raid events have been recorded yet.\nRun the game8 spider to populate data.'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Raid list (used by both tabs)
// ---------------------------------------------------------------------------
class _RaidList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRefresh;
  final String emptyMessage;

  const _RaidList({
    required this.future,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(onRefresh: onRefresh);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyState(message: emptyMessage, onRefresh: onRefresh);
        }
        final raids = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: raids.length,
          itemBuilder: (context, i) => _RaidCard(raid: raids[i]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual raid card
// ---------------------------------------------------------------------------
class _RaidCard extends StatelessWidget {
  final Map<String, dynamic> raid;
  const _RaidCard({required this.raid});

  @override
  Widget build(BuildContext context) {
    final pokemonName = raid['pokemon_name'] as String? ?? '';
    final teraType    = raid['tera_type']    as String?;
    final starRating  = raid['star_rating']  as int?;
    final eventStart  = raid['event_start']  as String?;
    final eventEnd    = raid['event_end']    as String?;
    final isActive    = raid['is_active']    as bool? ?? false;

    final teraColor = _typeColor(teraType);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCounters(context, pokemonName, teraType),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _displayName(pokemonName),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (starRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$starRating★',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              // ── Tera type badge ─────────────────────────────────────────
              if (teraType != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: teraColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$teraType Tera',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // ── Dates ───────────────────────────────────────────────────
              if (eventStart != null) ...[
                const SizedBox(height: 6),
                Text(
                  eventEnd != null
                      ? '$eventStart – $eventEnd'
                      : 'From $eventStart',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
              // ── Tap hint ────────────────────────────────────────────────
              const SizedBox(height: 6),
              Text(
                'Tap to see best counters →',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCounters(BuildContext context, String pokemonName, String? teraType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountersSheet(
        pokemonName: pokemonName,
        teraType: teraType,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Counters bottom sheet
// ---------------------------------------------------------------------------
class _CountersSheet extends StatefulWidget {
  final String pokemonName;
  final String? teraType;
  const _CountersSheet({required this.pokemonName, this.teraType});

  @override
  State<_CountersSheet> createState() => _CountersSheetState();
}

class _CountersSheetState extends State<_CountersSheet> {
  late Future<List<Map<String, dynamic>>> _countersFuture;
  late Future<List<Map<String, dynamic>>> _weaknessesFuture;

  @override
  void initState() {
    super.initState();
    _countersFuture = PokemonDBService.getRaidCounters(
      widget.pokemonName,
      teraType: widget.teraType,
    );
    _weaknessesFuture = PokeApiService.getPokemonTypeDefenses(widget.pokemonName);
  }

  @override
  Widget build(BuildContext context) {
    final teraColor = _typeColor(widget.teraType);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Handle + header ────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Best Counters — ${_displayName(widget.pokemonName)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.teraType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: teraColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.teraType} Tera',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                ],
              ),
            ),
            // ── Type weaknesses ────────────────────────────────────────
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _weaknessesFuture,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
                final weaknesses = snap.data!
                    .where((d) => (d['multiplier'] as num? ?? 1) > 1)
                    .toList()
                  ..sort((a, b) => (b['multiplier'] as num).compareTo(a['multiplier'] as num));
                if (weaknesses.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teraType != null
                            ? 'Base Type Weaknesses (pre-tera)'
                            : 'Type Weaknesses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: weaknesses.map((d) {
                          final type = d['type_name'] as String? ?? '';
                          final mult = d['multiplier'] as num? ?? 1;
                          final color = _typeColor(type);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$type ×${mult % 1 == 0 ? mult.toInt() : mult}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                );
              },
            ),
            // ── Counter list ───────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _countersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No counter data yet.\nRun the game8 spider to populate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  final counters = snapshot.data!;
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: counters.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = counters[i];
                      final rank  = c['rank'] as int?;
                      final name  = c['counter_pokemon'] as String? ?? '';
                      final notes = c['notes'] as String?;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            rank != null ? '$rank' : '—',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          _displayName(name),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: notes != null && notes.isNotEmpty
                            ? Text(
                                notes,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Error / empty states
// ---------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ErrorState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Could not load raid data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the API server is running and accessible.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;
  const _EmptyState({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
