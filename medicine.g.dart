// GENERATED CODE — normally produced by `flutter pub run build_runner build`.
// Included by hand here so the project compiles without a build step;
// regenerate with build_runner if you add/remove fields on Medicine.

part of 'medicine.dart';

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      quantityPerDose: fields[3] as int,
      timeSlots: (fields[4] as List).cast<String>(),
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime?,
      imagePath: fields[7] as String?,
      verificationCode: fields[8] as String?,
      alarmTimes: (fields[9] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.quantityPerDose)
      ..writeByte(4)
      ..write(obj.timeSlots)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.verificationCode)
      ..writeByte(9)
      ..write(obj.alarmTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
