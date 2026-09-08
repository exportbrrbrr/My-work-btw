import 'package:hive/hive.dart';

part 'medicine.g.dart';

/// Local-only medicine record. Everything — including the cropped pill
/// photo — is stored on-device: [imagePath] points into the app's own
/// documents directory, never to a remote bucket.
@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // ชื่อยา, e.g. "วิตามินซี 500มก."

  @HiveField(2)
  String type; // ประเภทยา, e.g. "เม็ด" / "แคปซูล" / "น้ำ"

  @HiveField(3)
  int quantityPerDose; // "กินกี่เม็ด" — added per spec

  @HiveField(4)
  List<String> timeSlots; // e.g. ["หลังอาหารเช้า"] or ["เช้า", "เย็น"]

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime? endDate; // "กินถึงวันที่เท่าไหร่" — added per spec, null = ongoing

  @HiveField(7)
  String? imagePath; // cropped pill photo, local file path only

  @HiveField(8)
  String? verificationCode; // payload of the QR/barcode stuck on the bottle

  @HiveField(9)
  List<String> alarmTimes; // ["08:00", "12:00", "18:00"] — 24h HH:mm

  Medicine({
    required this.id,
    required this.name,
    required this.type,
    required this.quantityPerDose,
    required this.timeSlots,
    required this.startDate,
    this.endDate,
    this.imagePath,
    this.verificationCode,
    required this.alarmTimes,
  });

  bool get isActiveToday {
    final today = DateTime.now();
    final started =
        !today.isBefore(DateTime(startDate.year, startDate.month, startDate.day));
    final notEnded = endDate == null ||
        !today.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day));
    return started && notEnded;
  }
}
