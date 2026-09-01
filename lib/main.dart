import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pokedex/Widgets/Search.dart';
import 'package:pokedex/Widgets/HomePage.dart';
import 'package:pokedex/Widgets/game_version_filter.dart';
import 'package:pokedex/Widgets/my_pokemon.dart';
import 'package:pokedex/Widgets/calculators.dart';
import 'package:pokedex/Widgets/ev_training_finder.dart';
import 'package:pokedex/Widgets/navigation/databases_hub.dart';
import 'package:pokedex/Widgets/navigation/tools_hub.dart';
import 'package:pokedex/Widgets/navigation/more_hub.dart';
import 'package:pokedex/Widgets/regional_dex_screen.dart';
import 'package:pokedex/models/saved_pokemon.dart';
import 'package:pokedex/models/pokemon_team.dart';
import 'package:pokedex/models/favorite_pokemon.dart';
import 'package:pokedex/models/nuzlocke_run.dart';
import 'package:pokedex/services/pokemon_storage_service.dart';
import 'package:pokedex/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(SavedPokemonAdapter());
  Hive.registerAdapter(PokemonTeamAdapter());
  Hive.registerAdapter(FavoritePokemonAdapter());
  Hive.registerAdapter(NuzlockeRunAdapter());

  // Initialize storage service
  await PokemonStorageService().initialize();

  // Load dark mode preference
  final settingsBox = await Hive.openBox('settings');
  final isDark = settingsBox.get('darkMode', defaultValue: false);

  runApp(MyApp(isDarkMode: isDark));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  const MyApp({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeDex',
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const Home(title: 'PokeDex'),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.title});
  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final bool isAndroid = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      primary: true,
      body: SafeArea(
        top: isAndroid,
        bottom: false,
        left: false,
        right: false,
        child: _getPage(currentPage),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            currentPage = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.catching_pokemon),
            label: 'Pokedex',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Database',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _getPage(int page) {
    switch (page) {
      case 0:
        return const HomePage();
      case 1:
        return const _PokedexTab();
      case 2:
        return const ToolsHub();
      case 3:
        return const MyPokemon();
      case 4:
        return const DatabasesHub();
      case 5:
        return const MoreHub();
      default:
        return const HomePage();
    }
  }
}

/// Pokedex tab with sub-navigation for Search, By Game, EV Training, Calculators
class _PokedexTab extends StatefulWidget {
  const _PokedexTab();

  @override
  State<_PokedexTab> createState() => _PokedexTabState();
}

class _PokedexTabState extends State<_PokedexTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.red,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('PokeDex', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Search'),
                    Tab(text: 'By Region'),
                    Tab(text: 'By Game'),
                    Tab(text: 'EV Train'),
                    Tab(text: 'Calc'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const Search(),
              const RegionalDexScreen(),
              const GameVersionFilter(),
              const EVTrainingFinder(),
              const Calculators(),
            ],
          ),
        ),
      ],
    );
  }
}
