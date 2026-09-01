// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_pokemon.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedPokemonAdapter extends TypeAdapter<SavedPokemon> {
  @override
  final int typeId = 0;

  @override
  SavedPokemon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedPokemon(
      id: fields[0] as String,
      speciesName: fields[1] as String,
      nickname: fields[2] as String?,
      level: fields[3] as int,
      nature: fields[4] as String,
      baseStats: (fields[5] as Map).cast<String, int>(),
      ivs: (fields[6] as Map).cast<String, int>(),
      evs: (fields[7] as Map).cast<String, int>(),
      calculatedStats: (fields[8] as Map).cast<String, int>(),
      spriteUrl: fields[9] as String?,
      caughtDate: fields[10] as DateTime,
      location: fields[11] as String?,
      moves: (fields[12] as List?)?.cast<String>(),
      ability: fields[13] as String?,
      isShiny: fields[14] as bool,
      pokeball: fields[15] as String?,
      friendship: fields[16] as int?,
      gender: fields[17] as String?,
      game: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedPokemon obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.speciesName)
      ..writeByte(2)
      ..write(obj.nickname)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.nature)
      ..writeByte(5)
      ..write(obj.baseStats)
      ..writeByte(6)
      ..write(obj.ivs)
      ..writeByte(7)
      ..write(obj.evs)
      ..writeByte(8)
      ..write(obj.calculatedStats)
      ..writeByte(9)
      ..write(obj.spriteUrl)
      ..writeByte(10)
      ..write(obj.caughtDate)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.moves)
      ..writeByte(13)
      ..write(obj.ability)
      ..writeByte(14)
      ..write(obj.isShiny)
      ..writeByte(15)
      ..write(obj.pokeball)
      ..writeByte(16)
      ..write(obj.friendship)
      ..writeByte(17)
      ..write(obj.gender)
      ..writeByte(18)
      ..write(obj.game);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPokemonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
