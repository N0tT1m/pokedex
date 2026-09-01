import 'package:hive/hive.dart';

part 'saved_pokemon.g.dart';

@HiveType(typeId: 0)
class SavedPokemon extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier for this individual Pokemon

  @HiveField(1)
  String speciesName; // e.g., "pikachu"

  @HiveField(2)
  String? nickname; // Optional nickname

  @HiveField(3)
  int level;

  @HiveField(4)
  String nature; // e.g., "Adamant", "Jolly"

  @HiveField(5)
  Map<String, int> baseStats; // Base stats from species

  @HiveField(6)
  Map<String, int> ivs; // Individual Values (0-31)

  @HiveField(7)
  Map<String, int> evs; // Effort Values (0-252 per stat, 510 total)

  @HiveField(8)
  Map<String, int> calculatedStats; // Final calculated stats

  @HiveField(9)
  String? spriteUrl; // Pokemon sprite image URL

  @HiveField(10)
  DateTime caughtDate;

  @HiveField(11)
  String? location; // Where it was caught

  @HiveField(12)
  List<String>? moves; // Up to 4 moves

  @HiveField(13)
  String? ability; // Pokemon ability

  @HiveField(14)
  bool isShiny;

  @HiveField(15)
  String? pokeball; // Type of pokeball used

  @HiveField(16)
  int? friendship; // Friendship level (0-255)

  @HiveField(17)
  String? gender; // "Male", "Female", or "Genderless"

  @HiveField(18)
  String? game; // Game version (e.g., "Scarlet/Violet", "Sword/Shield")

  SavedPokemon({
    required this.id,
    required this.speciesName,
    this.nickname,
    required this.level,
    required this.nature,
    required this.baseStats,
    required this.ivs,
    required this.evs,
    required this.calculatedStats,
    this.spriteUrl,
    required this.caughtDate,
    this.location,
    this.moves,
    this.ability,
    this.isShiny = false,
    this.pokeball,
    this.friendship,
    this.gender,
    this.game,
  });

  String get displayName => nickname ?? _capitalize(speciesName);

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // Calculate total IVs
  int get totalIVs {
    return ivs.values.fold(0, (sum, iv) => sum + iv);
  }

  // Calculate total EVs
  int get totalEVs {
    return evs.values.fold(0, (sum, ev) => sum + ev);
  }

  // Get IV percentage (out of max 186)
  double get ivPercentage {
    return (totalIVs / 186) * 100;
  }

  // Create a copy with updated fields
  SavedPokemon copyWith({
    String? id,
    String? speciesName,
    String? nickname,
    int? level,
    String? nature,
    Map<String, int>? baseStats,
    Map<String, int>? ivs,
    Map<String, int>? evs,
    Map<String, int>? calculatedStats,
    String? spriteUrl,
    DateTime? caughtDate,
    String? location,
    List<String>? moves,
    String? ability,
    bool? isShiny,
    String? pokeball,
    int? friendship,
    String? gender,
    String? game,
  }) {
    return SavedPokemon(
      id: id ?? this.id,
      speciesName: speciesName ?? this.speciesName,
      nickname: nickname ?? this.nickname,
      level: level ?? this.level,
      nature: nature ?? this.nature,
      baseStats: baseStats ?? this.baseStats,
      ivs: ivs ?? this.ivs,
      evs: evs ?? this.evs,
      calculatedStats: calculatedStats ?? this.calculatedStats,
      spriteUrl: spriteUrl ?? this.spriteUrl,
      caughtDate: caughtDate ?? this.caughtDate,
      location: location ?? this.location,
      moves: moves ?? this.moves,
      ability: ability ?? this.ability,
      isShiny: isShiny ?? this.isShiny,
      pokeball: pokeball ?? this.pokeball,
      friendship: friendship ?? this.friendship,
      gender: gender ?? this.gender,
      game: game ?? this.game,
    );
  }
}
