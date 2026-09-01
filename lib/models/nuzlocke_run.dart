import 'package:hive/hive.dart';

class NuzlockeRun extends HiveObject {
  String id;
  String name;
  String gameName;
  List<String> rules;
  DateTime startDate;
  bool isActive;
  List<NuzlockeEncounter> encounters;

  NuzlockeRun({
    required this.id,
    required this.name,
    required this.gameName,
    required this.rules,
    required this.startDate,
    this.isActive = true,
    List<NuzlockeEncounter>? encounters,
  }) : encounters = encounters ?? [];

  int get aliveCount => encounters.where((e) => e.status == 'alive').length;
  int get deadCount => encounters.where((e) => e.status == 'dead').length;
  int get boxedCount => encounters.where((e) => e.status == 'boxed').length;
  List<NuzlockeEncounter> get team => encounters.where((e) => e.status == 'alive' && e.inParty).toList();
}

class NuzlockeEncounter {
  String pokemonName;
  String? nickname;
  String routeName;
  String status; // 'alive', 'dead', 'boxed'
  int? level;
  String? deathDetails;
  bool inParty;

  NuzlockeEncounter({
    required this.pokemonName,
    this.nickname,
    required this.routeName,
    this.status = 'alive',
    this.level,
    this.deathDetails,
    this.inParty = false,
  });
}

class NuzlockeRunAdapter extends TypeAdapter<NuzlockeRun> {
  @override
  final int typeId = 3;

  @override
  NuzlockeRun read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final encountersList = (fields[6] as List?)?.cast<Map>() ?? [];
    return NuzlockeRun(
      id: fields[0] as String,
      name: fields[1] as String,
      gameName: fields[2] as String,
      rules: (fields[3] as List).cast<String>(),
      startDate: fields[4] as DateTime,
      isActive: fields[5] as bool? ?? true,
      encounters: encountersList.map((m) => NuzlockeEncounter(
        pokemonName: m['pokemonName'] ?? '',
        nickname: m['nickname'],
        routeName: m['routeName'] ?? '',
        status: m['status'] ?? 'alive',
        level: m['level'],
        deathDetails: m['deathDetails'],
        inParty: m['inParty'] ?? false,
      )).toList(),
    );
  }

  @override
  void write(BinaryWriter writer, NuzlockeRun obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.gameName)
      ..writeByte(3)
      ..write(obj.rules)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.encounters.map((e) => {
        'pokemonName': e.pokemonName,
        'nickname': e.nickname,
        'routeName': e.routeName,
        'status': e.status,
        'level': e.level,
        'deathDetails': e.deathDetails,
        'inParty': e.inParty,
      }).toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NuzlockeRunAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
