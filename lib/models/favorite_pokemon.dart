import 'package:hive/hive.dart';

class FavoritePokemon extends HiveObject {
  String speciesName;
  DateTime addedDate;
  String? notes;
  int? nationalDexNumber;
  String? spriteUrl;

  FavoritePokemon({
    required this.speciesName,
    required this.addedDate,
    this.notes,
    this.nationalDexNumber,
    this.spriteUrl,
  });
}

class FavoritePokemonAdapter extends TypeAdapter<FavoritePokemon> {
  @override
  final int typeId = 2;

  @override
  FavoritePokemon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoritePokemon(
      speciesName: fields[0] as String,
      addedDate: fields[1] as DateTime,
      notes: fields[2] as String?,
      nationalDexNumber: fields[3] as int?,
      spriteUrl: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FavoritePokemon obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.speciesName)
      ..writeByte(1)
      ..write(obj.addedDate)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.nationalDexNumber)
      ..writeByte(4)
      ..write(obj.spriteUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoritePokemonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
