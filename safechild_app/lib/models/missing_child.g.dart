// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_child.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissingChildAdapter extends TypeAdapter<MissingChild> {
  @override
  final int typeId = 0;

  @override
  MissingChild read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MissingChild(
      id: fields[0] as int?,
      userId: fields[1] as int,
      name: fields[2] as String,
      age: fields[3] as int,
      photoUrl: fields[4] as String?,
      description: fields[5] as String?,
      lastClothes: fields[6] as String?,
      status: fields[7] as String,
      disappearanceLat: fields[8] as double,
      disappearanceLng: fields[9] as double,
      disappearedAt: fields[10] as DateTime,
      isVerified: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MissingChild obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.photoUrl)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.lastClothes)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.disappearanceLat)
      ..writeByte(9)
      ..write(obj.disappearanceLng)
      ..writeByte(10)
      ..write(obj.disappearedAt)
      ..writeByte(11)
      ..write(obj.isVerified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingChildAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
