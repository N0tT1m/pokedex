// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_team.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PokemonTeamAdapter extends TypeAdapter<PokemonTeam> {
  @override
  final int typeId = 1;

  @override
  PokemonTeam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PokemonTeam(
      id: fields[0] as String,
      name: fields[1] as String,
      pokemonIds: (fields[2] as List).cast<String>(),
      createdDate: fields[3] as DateTime,
      lastModified: fields[4] as DateTime,
      description: fields[5] as String?,
      game: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PokemonTeam obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.pokemonIds)
      ..writeByte(3)
      ..write(obj.createdDate)
      ..writeByte(4)
      ..write(obj.lastModified)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.game);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonTeamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
