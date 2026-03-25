import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'pokemon_detail_sheet.dart';

class RegionalFormsScreen extends StatefulWidget {
  const RegionalFormsScreen({Key? key}) : super(key: key);

  @override
  State<RegionalFormsScreen> createState() => _RegionalFormsScreenState();
}

class _RegionalFormsScreenState extends State<RegionalFormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Map display region names to PokeAPI region suffixes
  static const _regionToApi = <String, String>{
    'Alolan': 'alola',
    'Galarian': 'galar',
    'Hisuian': 'hisui',
    'Paldean': 'paldea',
  };

  // Pokemon whose PokeAPI name doesn't match the simple "{base}-{region}" pattern
  static const _specialFormNames = <String, String>{
    'darmanitan-galar': 'darmanitan-galar-standard',
    'tauros (combat)-paldea': 'tauros-paldea-combat-breed',
    'tauros (blaze)-paldea': 'tauros-paldea-blaze-breed',
    'tauros (aqua)-paldea': 'tauros-paldea-aqua-breed',
  };

  // Hardcoded regional form data since PokeAPI doesn't have a clean endpoint for this
  static const Map<String, List<Map<String, String>>> _regionalForms = {
    'Alolan': [
      {'name': 'Rattata', 'types': 'Dark, Normal'}, {'name': 'Raticate', 'types': 'Dark, Normal'},
      {'name': 'Raichu', 'types': 'Electric, Psychic'}, {'name': 'Sandshrew', 'types': 'Ice, Steel'},
      {'name': 'Sandslash', 'types': 'Ice, Steel'}, {'name': 'Vulpix', 'types': 'Ice'},
      {'name': 'Ninetales', 'types': 'Ice, Fairy'}, {'name': 'Diglett', 'types': 'Ground, Steel'},
      {'name': 'Dugtrio', 'types': 'Ground, Steel'}, {'name': 'Meowth', 'types': 'Dark'},
      {'name': 'Persian', 'types': 'Dark'}, {'name': 'Geodude', 'types': 'Rock, Electric'},
      {'name': 'Graveler', 'types': 'Rock, Electric'}, {'name': 'Golem', 'types': 'Rock, Electric'},
      {'name': 'Grimer', 'types': 'Poison, Dark'}, {'name': 'Muk', 'types': 'Poison, Dark'},
      {'name': 'Exeggutor', 'types': 'Grass, Dragon'}, {'name': 'Marowak', 'types': 'Fire, Ghost'},
    ],
    'Galarian': [
      {'name': 'Meowth', 'types': 'Steel'}, {'name': 'Ponyta', 'types': 'Psychic'},
      {'name': 'Rapidash', 'types': 'Psychic, Fairy'}, {'name': 'Slowpoke', 'types': 'Psychic'},
      {'name': 'Slowbro', 'types': 'Poison, Psychic'}, {'name': 'Slowking', 'types': 'Poison, Psychic'},
      {'name': "Farfetch'd", 'types': 'Fighting'}, {'name': 'Weezing', 'types': 'Poison, Fairy'},
      {'name': 'Mr. Mime', 'types': 'Ice, Psychic'}, {'name': 'Articuno', 'types': 'Psychic, Flying'},
      {'name': 'Zapdos', 'types': 'Fighting, Flying'}, {'name': 'Moltres', 'types': 'Dark, Flying'},
      {'name': 'Corsola', 'types': 'Ghost'}, {'name': 'Zigzagoon', 'types': 'Dark, Normal'},
      {'name': 'Linoone', 'types': 'Dark, Normal'}, {'name': 'Darumaka', 'types': 'Ice'},
      {'name': 'Darmanitan', 'types': 'Ice'}, {'name': 'Yamask', 'types': 'Ground, Ghost'},
      {'name': 'Stunfisk', 'types': 'Ground, Steel'},
    ],
    'Hisuian': [
      {'name': 'Growlithe', 'types': 'Fire, Rock'}, {'name': 'Arcanine', 'types': 'Fire, Rock'},
      {'name': 'Voltorb', 'types': 'Electric, Grass'}, {'name': 'Electrode', 'types': 'Electric, Grass'},
      {'name': 'Typhlosion', 'types': 'Fire, Ghost'}, {'name': 'Qwilfish', 'types': 'Dark, Poison'},
      {'name': 'Sneasel', 'types': 'Fighting, Poison'}, {'name': 'Samurott', 'types': 'Water, Dark'},
      {'name': 'Lilligant', 'types': 'Grass, Fighting'}, {'name': 'Zorua', 'types': 'Normal, Ghost'},
      {'name': 'Zoroark', 'types': 'Normal, Ghost'}, {'name': 'Braviary', 'types': 'Psychic, Flying'},
      {'name': 'Sliggoo', 'types': 'Steel, Dragon'}, {'name': 'Goodra', 'types': 'Steel, Dragon'},
      {'name': 'Avalugg', 'types': 'Ice, Rock'}, {'name': 'Decidueye', 'types': 'Grass, Fighting'},
    ],
    'Paldean': [
      {'name': 'Tauros (Combat)', 'types': 'Fighting'}, {'name': 'Tauros (Blaze)', 'types': 'Fighting, Fire'},
      {'name': 'Tauros (Aqua)', 'types': 'Fighting, Water'}, {'name': 'Wooper', 'types': 'Poison, Ground'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _regionalForms.length, vsync: this);
    _isLoading = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regions = _regionalForms.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Forms'),
        backgroundColor: Colors.red,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: regions.map((r) => Tab(text: r)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: regions.map((region) {
          final forms = _regionalForms[region]!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: forms.length,
            itemBuilder: (context, index) {
              final form = forms[index];
              final types = form['types']!.split(', ');

              // Build API name for regional form lookup
              final rawName = form['name']!;
              final baseName = rawName.toLowerCase().replaceAll('. ', '-').replaceAll("'", '');
              final regionApi = _regionToApi[region] ?? region.toLowerCase();
              // Special cases where PokeAPI uses a different name
              final specialKey = '$baseName-$regionApi';
              final apiName = _specialFormNames[specialKey] ?? '${baseName.split(' (')[0]}-$regionApi';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text('$region ${form['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: types.map((t) => Container(
                      margin: const EdgeInsets.only(right: 4, top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.typeColors[t.trim()],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.trim(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                    )).toList(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showPokemonDetailSheet(context, apiName),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
