import 'package:hive/hive.dart';

part 'pokemon_team.g.dart';

@HiveType(typeId: 1)
class PokemonTeam extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> pokemonIds; // List of SavedPokemon IDs (max 6)

  @HiveField(3)
  DateTime createdDate;

  @HiveField(4)
  DateTime lastModified;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? game; // e.g., "Scarlet/Violet", "Sword/Shield"

  PokemonTeam({
    required this.id,
    required this.name,
    required this.pokemonIds,
    required this.createdDate,
    required this.lastModified,
    this.description,
    this.game,
  });

  bool get isFull => pokemonIds.length >= 6;

  int get size => pokemonIds.length;

  PokemonTeam copyWith({
    String? id,
    String? name,
    List<String>? pokemonIds,
    DateTime? createdDate,
    DateTime? lastModified,
    String? description,
    String? game,
  }) {
    return PokemonTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      pokemonIds: pokemonIds ?? this.pokemonIds,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      description: description ?? this.description,
      game: game ?? this.game,
    );
  }
}
