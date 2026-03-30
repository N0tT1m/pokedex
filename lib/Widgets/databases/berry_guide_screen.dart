import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import '../../services/pokeapi_service.dart';

class BerryGuideScreen extends StatefulWidget {
  const BerryGuideScreen({Key? key}) : super(key: key);

  @override
  State<BerryGuideScreen> createState() => _BerryGuideScreenState();
}

class _BerryGuideScreenState extends State<BerryGuideScreen> {
  List<Map<String, dynamic>> _berries = [];
  List<Map<String, dynamic>> _filteredBerries = [];
  String _filter = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  // Curated berry data with competitive info (fallback)
  static const List<Map<String, dynamic>> _berryData = [
    // Healing
    {'name': 'Sitrus Berry', 'effect': 'Restores 25% HP when below 50% HP', 'category': 'Healing', 'competitive': true},
    {'name': 'Oran Berry', 'effect': 'Restores 10 HP when below 50% HP', 'category': 'Healing', 'competitive': false},
    {'name': 'Aguav Berry', 'effect': 'Restores 33% HP below 25% HP. Confuses if -SpDef nature', 'category': 'Healing', 'competitive': true},
    {'name': 'Figy Berry', 'effect': 'Restores 33% HP below 25% HP. Confuses if -Atk nature', 'category': 'Healing', 'competitive': true},
    {'name': 'Iapapa Berry', 'effect': 'Restores 33% HP below 25% HP. Confuses if -Def nature', 'category': 'Healing', 'competitive': true},
    {'name': 'Mago Berry', 'effect': 'Restores 33% HP below 25% HP. Confuses if -Spd nature', 'category': 'Healing', 'competitive': true},
    {'name': 'Wiki Berry', 'effect': 'Restores 33% HP below 25% HP. Confuses if -SpAtk nature', 'category': 'Healing', 'competitive': true},

    // Status cure
    {'name': 'Lum Berry', 'effect': 'Cures any status condition (one-time)', 'category': 'Status', 'competitive': true},
    {'name': 'Cheri Berry', 'effect': 'Cures Paralysis', 'category': 'Status', 'competitive': false},
    {'name': 'Chesto Berry', 'effect': 'Cures Sleep', 'category': 'Status', 'competitive': true},
    {'name': 'Pecha Berry', 'effect': 'Cures Poison', 'category': 'Status', 'competitive': false},
    {'name': 'Rawst Berry', 'effect': 'Cures Burn', 'category': 'Status', 'competitive': false},
    {'name': 'Aspear Berry', 'effect': 'Cures Freeze', 'category': 'Status', 'competitive': false},
    {'name': 'Persim Berry', 'effect': 'Cures Confusion', 'category': 'Status', 'competitive': false},

    // Pinch stat boost
    {'name': 'Liechi Berry', 'effect': '+1 Attack when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Ganlon Berry', 'effect': '+1 Defense when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Salac Berry', 'effect': '+1 Speed when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Petaya Berry', 'effect': '+1 Sp. Atk when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Apicot Berry', 'effect': '+1 Sp. Def when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Lansat Berry', 'effect': '+1 Critical hit ratio when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Starf Berry', 'effect': '+2 random stat when below 25% HP', 'category': 'Pinch', 'competitive': true},
    {'name': 'Micle Berry', 'effect': '+20% accuracy on next move below 25% HP', 'category': 'Pinch', 'competitive': false},
    {'name': 'Custap Berry', 'effect': 'Move first next turn when below 25% HP', 'category': 'Pinch', 'competitive': true},

    // Type resist
    {'name': 'Occa Berry', 'effect': 'Halves super effective Fire damage (one-time)', 'category': 'Resist', 'competitive': true},
    {'name': 'Passho Berry', 'effect': 'Halves super effective Water damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Wacan Berry', 'effect': 'Halves super effective Electric damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Rindo Berry', 'effect': 'Halves super effective Grass damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Yache Berry', 'effect': 'Halves super effective Ice damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Chople Berry', 'effect': 'Halves super effective Fighting damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Kebia Berry', 'effect': 'Halves super effective Poison damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Shuca Berry', 'effect': 'Halves super effective Ground damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Coba Berry', 'effect': 'Halves super effective Flying damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Payapa Berry', 'effect': 'Halves super effective Psychic damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Tanga Berry', 'effect': 'Halves super effective Bug damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Charti Berry', 'effect': 'Halves super effective Rock damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Kasib Berry', 'effect': 'Halves super effective Ghost damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Haban Berry', 'effect': 'Halves super effective Dragon damage', 'category': 'Resist', 'competitive': true},
    {'name': 'Colbur Berry', 'effect': 'Halves super effective Dark damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Babiri Berry', 'effect': 'Halves super effective Steel damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Roseli Berry', 'effect': 'Halves super effective Fairy damage', 'category': 'Resist', 'competitive': false},
    {'name': 'Chilan Berry', 'effect': 'Halves Normal-type damage', 'category': 'Resist', 'competitive': false},

    // EV reducing
    {'name': 'Pomeg Berry', 'effect': 'Reduces HP EVs by 10', 'category': 'EV', 'competitive': true},
    {'name': 'Kelpsy Berry', 'effect': 'Reduces Attack EVs by 10', 'category': 'EV', 'competitive': true},
    {'name': 'Qualot Berry', 'effect': 'Reduces Defense EVs by 10', 'category': 'EV', 'competitive': true},
    {'name': 'Hondew Berry', 'effect': 'Reduces Sp. Atk EVs by 10', 'category': 'EV', 'competitive': true},
    {'name': 'Grepa Berry', 'effect': 'Reduces Sp. Def EVs by 10', 'category': 'EV', 'competitive': true},
    {'name': 'Tamato Berry', 'effect': 'Reduces Speed EVs by 10', 'category': 'EV', 'competitive': true},

    // Other competitive
    {'name': 'Leppa Berry', 'effect': 'Restores 10 PP when a move hits 0 PP', 'category': 'Other', 'competitive': true},
    {'name': 'Enigma Berry', 'effect': 'Restores 25% HP when hit by super effective move', 'category': 'Other', 'competitive': false},
    {'name': 'Jaboca Berry', 'effect': 'Deals 12.5% to attacker when hit by physical move', 'category': 'Other', 'competitive': false},
    {'name': 'Rowap Berry', 'effect': 'Deals 12.5% to attacker when hit by special move', 'category': 'Other', 'competitive': false},
    {'name': 'Kee Berry', 'effect': '+1 Defense when hit by physical move', 'category': 'Other', 'competitive': true},
    {'name': 'Maranga Berry', 'effect': '+1 Sp. Def when hit by special move', 'category': 'Other', 'competitive': true},
  ];

  static const List<String> _categories = ['all', 'Healing', 'Status', 'Pinch', 'Resist', 'EV', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadBerriesFromApi();
  }

  Future<void> _loadBerriesFromApi() async {
    try {
      final response = await Requests.get('${PokeApiService.baseUrl}/berry?limit=100');
      if (response.statusCode == 200) {
        final data = response.json();
        final results = List<Map<String, dynamic>>.from(data['results']);
        final List<Map<String, dynamic>> apiBerries = [];

        for (final berry in results) {
          try {
            final detailUrl = '${PokeApiService.baseUrl}/berry/${berry['name']}';
            final detailResponse = await Requests.get(detailUrl);
            if (detailResponse.statusCode == 200) {
              final detail = detailResponse.json();
              final rawName = detail['name'] as String;
              final displayName = rawName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

              final effect = detail['effect']?.toString() ?? '';
              final naturalGiftType = detail['natural_gift_type']?.toString() ?? '';
              final naturalGiftPower = detail['natural_gift_power'] ?? 0;
              final firmness = detail['firmness'] is Map ? detail['firmness']['name']?.toString() ?? '' : '';
              final growthTime = detail['growth_time'] ?? 0;

              // Build a descriptive effect string
              String effectText = effect.isNotEmpty
                  ? effect
                  : 'Natural Gift: $naturalGiftType (Power $naturalGiftPower)';
              if (firmness.isNotEmpty) {
                effectText += ' | Firmness: ${firmness[0].toUpperCase()}${firmness.substring(1)}';
              }
              if (growthTime > 0) {
                effectText += ' | Growth: ${growthTime}h';
              }

              apiBerries.add({
                'name': displayName,
                'effect': effectText,
                'category': 'Other',
                'competitive': false,
              });
            }
          } catch (_) {
            // Skip individual berry failures
          }
        }

        if (apiBerries.isNotEmpty && mounted) {
          // Merge: keep hardcoded entries (they have curated categories/competitive tags),
          // add any API berries not already in the hardcoded list
          final hardcodedNames = _berryData.map((b) => (b['name'] as String).toLowerCase()).toSet();
          final newBerries = apiBerries.where(
            (b) => !hardcodedNames.contains((b['name'] as String).toLowerCase()),
          ).toList();

          setState(() {
            _berries = [..._berryData, ...newBerries];
            _filteredBerries = _berries;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // API failed; fall back to hardcoded data
    }

    // Fallback to hardcoded data
    if (mounted) {
      setState(() {
        _berries = _berryData;
        _filteredBerries = _berries;
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredBerries = _berries.where((b) {
        bool matchesCategory = _filter == 'all' || b['category'] == _filter;
        bool matchesSearch = _searchQuery.isEmpty ||
          (b['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (b['effect'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Berry Guide'), backgroundColor: Colors.red),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search berries...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) { _searchQuery = v; _applyFilter(); },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c == 'all' ? 'All' : c),
                  selected: _filter == c,
                  onSelected: (_) { _filter = c; _applyFilter(); },
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredBerries.length,
              itemBuilder: (context, index) {
                final berry = _filteredBerries[index];
                final isCompetitive = berry['competitive'] as bool;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _categoryColor(berry['category']),
                      child: const Icon(Icons.eco, color: Colors.white, size: 18),
                    ),
                    title: Row(
                      children: [
                        Text(berry['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (isCompetitive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Comp', style: TextStyle(fontSize: 9, color: Colors.amber)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(berry['effect'], style: const TextStyle(fontSize: 12)),
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Healing': return Colors.green;
      case 'Status': return Colors.blue;
      case 'Pinch': return Colors.orange;
      case 'Resist': return Colors.purple;
      case 'EV': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
