import 'package:flutter/material.dart';
import 'package:requests/requests.dart';

import '../../services/pokeapi_service.dart';
import '../../theme/app_theme.dart';
import 'pokemon_detail_sheet.dart';

class RegionalFormsScreen extends StatefulWidget {
  const RegionalFormsScreen({Key? key}) : super(key: key);

  @override
  State<RegionalFormsScreen> createState() => _RegionalFormsScreenState();
}

class _RegionalFormsScreenState extends State<RegionalFormsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
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

  // Hardcoded fallback regional form data
  static const Map<String, List<Map<String, String>>> _fallbackForms = {
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

  // Live data from API, keyed by region
  Map<String, List<Map<String, dynamic>>> _regionalForms = {};

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    // Try to load forms from the API for every Pokemon that has regional variants
    final Map<String, List<Map<String, dynamic>>> loaded = {};

    // Collect all base Pokemon names from the fallback list
    final allBaseNames = <String>{};
    for (final forms in _fallbackForms.values) {
      for (final f in forms) {
        // Strip parenthetical variants like "Tauros (Combat)"
        allBaseNames.add(f['name']!.split(' (')[0].toLowerCase().replaceAll('. ', '-').replaceAll("'", ''));
      }
    }

    // Fetch forms for each base Pokemon from the API
    final Map<String, List<Map<String, dynamic>>> formsByPokemon = {};
    await Future.wait(allBaseNames.map((name) async {
      try {
        final response = await Requests.get('${PokeApiService.baseUrl}/pokemon/$name/forms');
        if (response.statusCode == 200) {
          final data = response.json();
          final forms = List<Map<String, dynamic>>.from(data['forms'] ?? []);
          if (forms.isNotEmpty) {
            formsByPokemon[name] = forms;
          }
        }
      } catch (_) {}
    }));

    if (formsByPokemon.isNotEmpty) {
      // Group API forms by region
      for (final entry in _regionToApi.entries) {
        final regionLabel = entry.key; // e.g. "Alolan"
        final regionSuffix = entry.value; // e.g. "alola"
        final regionForms = <Map<String, dynamic>>[];

        for (final pokeForms in formsByPokemon.entries) {
          for (final form in pokeForms.value) {
            final formName = (form['form_name'] as String? ?? '').toLowerCase();
            if (formName.contains(regionSuffix)) {
              regionForms.add(form);
            }
          }
        }
        if (regionForms.isNotEmpty) {
          loaded[regionLabel] = regionForms;
        }
      }
    }

    // Fall back to hardcoded data for any region that didn't load
    for (final region in _fallbackForms.keys) {
      if (!loaded.containsKey(region) || loaded[region]!.isEmpty) {
        loaded[region] = _fallbackForms[region]!.map((f) => <String, dynamic>{
          'pokemon_name': f['name']!.split(' (')[0],
          'form_name': '$region ${f['name']}',
          'types': f['types']!.split(', '),
          '_fallback': true,
          '_displayName': f['name'],
        }).toList();
      }
    }

    if (mounted) {
      setState(() {
        _regionalForms = loaded;
        _tabController = TabController(length: _regionalForms.length, vsync: this);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _formatName(String name) =>
      name.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Regional Forms'), backgroundColor: Colors.red),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        controller: _tabController!,
        children: regions.map((region) {
          final forms = _regionalForms[region]!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: forms.length,
            itemBuilder: (context, index) {
              final form = forms[index];
              final isFallback = form['_fallback'] == true;

              // Extract display info
              final String displayName;
              final List<String> types;
              final String apiName;

              if (isFallback) {
                displayName = '$region ${form['_displayName']}';
                types = List<String>.from(form['types']);
                final rawName = (form['_displayName'] as String);
                final baseName = rawName.toLowerCase().replaceAll('. ', '-').replaceAll("'", '');
                final regionApi = _regionToApi[region] ?? region.toLowerCase();
                final specialKey = '$baseName-$regionApi';
                apiName = _specialFormNames[specialKey] ?? '${baseName.split(' (')[0]}-$regionApi';
              } else {
                final formName = form['form_name'] as String? ?? '';
                final pokemonName = form['pokemon_name'] as String? ?? '';
                displayName = formName.isNotEmpty ? _formatName(formName) : '$region ${_formatName(pokemonName)}';
                types = List<String>.from(form['types'] ?? []);
                apiName = formName.isNotEmpty
                    ? formName.toLowerCase().replaceAll(' ', '-')
                    : '${pokemonName.toLowerCase()}-${(_regionToApi[region] ?? region).toLowerCase()}';
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: types.map((t) {
                      final typeName = t.trim();
                      final capitalizedType = typeName.isNotEmpty
                          ? typeName[0].toUpperCase() + typeName.substring(1)
                          : typeName;
                      return Container(
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.typeColors[capitalizedType] ?? AppTheme.typeColors[typeName],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(capitalizedType, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      );
                    }).toList(),
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
