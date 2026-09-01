import 'package:hive/hive.dart';
import '../models/saved_pokemon.dart';
import '../models/pokemon_team.dart';

class PokemonStorageService {
  static const String _pokemonBoxName = 'saved_pokemon';
  static const String _teamsBoxName = 'pokemon_teams';

  // Singleton pattern
  static final PokemonStorageService _instance =
      PokemonStorageService._internal();
  factory PokemonStorageService() => _instance;
  PokemonStorageService._internal();

  Box<SavedPokemon>? _pokemonBox;
  Box<PokemonTeam>? _teamBox;

  // Initialize Hive and open boxes
  Future<void> initialize() async {
    _pokemonBox = await Hive.openBox<SavedPokemon>(_pokemonBoxName);
    _teamBox = await Hive.openBox<PokemonTeam>(_teamsBoxName);
  }

  // ==================== POKEMON CRUD ====================

  /// Save a new Pokemon
  Future<void> savePokemon(SavedPokemon pokemon) async {
    await _pokemonBox!.put(pokemon.id, pokemon);
  }

  /// Get a Pokemon by ID
  SavedPokemon? getPokemon(String id) {
    return _pokemonBox!.get(id);
  }

  /// Get all saved Pokemon
  List<SavedPokemon> getAllPokemon() {
    return _pokemonBox!.values.toList();
  }

  /// Get Pokemon by species
  List<SavedPokemon> getPokemonBySpecies(String speciesName) {
    return _pokemonBox!.values
        .where((p) => p.speciesName.toLowerCase() == speciesName.toLowerCase())
        .toList();
  }

  /// Update a Pokemon
  Future<void> updatePokemon(SavedPokemon pokemon) async {
    await _pokemonBox!.put(pokemon.id, pokemon);
  }

  /// Delete a Pokemon
  Future<void> deletePokemon(String id) async {
    await _pokemonBox!.delete(id);

    // Also remove from any teams
    final teams = getAllTeams();
    for (var team in teams) {
      if (team.pokemonIds.contains(id)) {
        team.pokemonIds.remove(id);
        team.lastModified = DateTime.now();
        await updateTeam(team);
      }
    }
  }

  /// Search Pokemon by nickname or species name
  List<SavedPokemon> searchPokemon(String query) {
    final lowerQuery = query.toLowerCase();
    return _pokemonBox!.values
        .where((p) =>
            p.speciesName.toLowerCase().contains(lowerQuery) ||
            (p.nickname?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }

  /// Get Pokemon count
  int get pokemonCount => _pokemonBox!.length;

  // ==================== TEAM CRUD ====================

  /// Create a new team
  Future<void> createTeam(PokemonTeam team) async {
    await _teamBox!.put(team.id, team);
  }

  /// Get a team by ID
  PokemonTeam? getTeam(String id) {
    return _teamBox!.get(id);
  }

  /// Get all teams
  List<PokemonTeam> getAllTeams() {
    return _teamBox!.values.toList();
  }

  /// Update a team
  Future<void> updateTeam(PokemonTeam team) async {
    team.lastModified = DateTime.now();
    await _teamBox!.put(team.id, team);
  }

  /// Delete a team
  Future<void> deleteTeam(String id) async {
    await _teamBox!.delete(id);
  }

  /// Add Pokemon to team
  Future<bool> addPokemonToTeam(String teamId, String pokemonId) async {
    final team = getTeam(teamId);
    if (team == null) return false;

    if (team.isFull) return false;
    if (team.pokemonIds.contains(pokemonId)) return false;

    team.pokemonIds.add(pokemonId);
    await updateTeam(team);
    return true;
  }

  /// Remove Pokemon from team
  Future<bool> removePokemonFromTeam(String teamId, String pokemonId) async {
    final team = getTeam(teamId);
    if (team == null) return false;

    if (!team.pokemonIds.contains(pokemonId)) return false;

    team.pokemonIds.remove(pokemonId);
    await updateTeam(team);
    return true;
  }

  /// Get Pokemon in a team
  List<SavedPokemon> getTeamPokemon(String teamId) {
    final team = getTeam(teamId);
    if (team == null) return [];

    return team.pokemonIds
        .map((id) => getPokemon(id))
        .where((p) => p != null)
        .cast<SavedPokemon>()
        .toList();
  }

  /// Get team count
  int get teamCount => _teamBox!.length;

  // ==================== IMPORT/EXPORT ====================

  /// Export all Pokemon to JSON
  List<Map<String, dynamic>> exportPokemon() {
    return getAllPokemon().map((p) => _pokemonToJson(p)).toList();
  }

  /// Export all teams to JSON
  List<Map<String, dynamic>> exportTeams() {
    return getAllTeams().map((t) => _teamToJson(t)).toList();
  }

  /// Import Pokemon from JSON
  Future<int> importPokemon(List<Map<String, dynamic>> jsonList) async {
    int imported = 0;
    for (var json in jsonList) {
      try {
        final pokemon = _pokemonFromJson(json);
        await savePokemon(pokemon);
        imported++;
      } catch (e) {
        // Skip invalid entries
        print('Failed to import Pokemon: $e');
      }
    }
    return imported;
  }

  /// Import teams from JSON
  Future<int> importTeams(List<Map<String, dynamic>> jsonList) async {
    int imported = 0;
    for (var json in jsonList) {
      try {
        final team = _teamFromJson(json);
        await createTeam(team);
        imported++;
      } catch (e) {
        // Skip invalid entries
        print('Failed to import team: $e');
      }
    }
    return imported;
  }

  // ==================== STATISTICS ====================

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final pokemon = getAllPokemon();
    final teams = getAllTeams();

    // Count unique species
    final speciesSet = pokemon.map((p) => p.speciesName).toSet();

    // Average IVs
    double avgIVs = 0;
    if (pokemon.isNotEmpty) {
      avgIVs = pokemon.map((p) => p.totalIVs).reduce((a, b) => a + b) / pokemon.length;
    }

    // Shiny count
    final shinyCount = pokemon.where((p) => p.isShiny).length;

    return {
      'totalPokemon': pokemon.length,
      'uniqueSpecies': speciesSet.length,
      'totalTeams': teams.length,
      'averageIVs': avgIVs,
      'shinyCount': shinyCount,
    };
  }

  // ==================== HELPER METHODS ====================

  Map<String, dynamic> _pokemonToJson(SavedPokemon p) {
    return {
      'id': p.id,
      'speciesName': p.speciesName,
      'nickname': p.nickname,
      'level': p.level,
      'nature': p.nature,
      'baseStats': p.baseStats,
      'ivs': p.ivs,
      'evs': p.evs,
      'calculatedStats': p.calculatedStats,
      'spriteUrl': p.spriteUrl,
      'caughtDate': p.caughtDate.toIso8601String(),
      'location': p.location,
      'moves': p.moves,
      'ability': p.ability,
      'isShiny': p.isShiny,
      'pokeball': p.pokeball,
      'friendship': p.friendship,
      'gender': p.gender,
      'game': p.game,
    };
  }

  SavedPokemon _pokemonFromJson(Map<String, dynamic> json) {
    return SavedPokemon(
      id: json['id'],
      speciesName: json['speciesName'],
      nickname: json['nickname'],
      level: json['level'],
      nature: json['nature'],
      baseStats: Map<String, int>.from(json['baseStats']),
      ivs: Map<String, int>.from(json['ivs']),
      evs: Map<String, int>.from(json['evs']),
      calculatedStats: Map<String, int>.from(json['calculatedStats']),
      spriteUrl: json['spriteUrl'],
      caughtDate: DateTime.parse(json['caughtDate']),
      location: json['location'],
      moves: json['moves'] != null ? List<String>.from(json['moves']) : null,
      ability: json['ability'],
      isShiny: json['isShiny'] ?? false,
      pokeball: json['pokeball'],
      friendship: json['friendship'],
      gender: json['gender'],
      game: json['game'],
    );
  }

  Map<String, dynamic> _teamToJson(PokemonTeam t) {
    return {
      'id': t.id,
      'name': t.name,
      'pokemonIds': t.pokemonIds,
      'createdDate': t.createdDate.toIso8601String(),
      'lastModified': t.lastModified.toIso8601String(),
      'description': t.description,
      'game': t.game,
    };
  }

  PokemonTeam _teamFromJson(Map<String, dynamic> json) {
    return PokemonTeam(
      id: json['id'],
      name: json['name'],
      pokemonIds: List<String>.from(json['pokemonIds']),
      createdDate: DateTime.parse(json['createdDate']),
      lastModified: DateTime.parse(json['lastModified']),
      description: json['description'],
      game: json['game'],
    );
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    await _pokemonBox!.clear();
    await _teamBox!.clear();
  }
}
