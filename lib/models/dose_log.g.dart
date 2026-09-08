// GENERATED CODE — see medicine.g.dart for the note on why this is hand-written.

part of 'dose_log.dart';

class DoseLogAdapter extends TypeAdapter<DoseLog> {
  @override
  final int typeId = 1;

  @override
  DoseLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoseLog(
      id: fields[0] as String,
      medicineId: fields[1] as String,
      scheduledTime: fields[2] as DateTime,
      takenTime: fields[3] as DateTime?,
      taken: fields[4] as bool,
      skipped: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DoseLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineId)
      ..writeByte(2)
      ..write(obj.scheduledTime)
      ..writeByte(3)
      ..write(obj.takenTime)
      ..writeByte(4)
      ..write(obj.taken)
      ..writeByte(5)
      ..write(obj.skipped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
