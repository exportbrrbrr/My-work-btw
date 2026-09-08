import 'package:hive/hive.dart';

part 'dose_log.g.dart';

/// One scheduled dose occurrence — populates the calendar (ปฏิทินกินยา)
/// and tells the alarm screen which occurrence a barcode scan confirms.
@HiveType(typeId: 1)
class DoseLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicineId;

  @HiveField(2)
  DateTime scheduledTime;

  @HiveField(3)
  DateTime? takenTime;

  @HiveField(4)
  bool taken;

  @HiveField(5)
  bool skipped;

  DoseLog({
    required this.id,
    required this.medicineId,
    required this.scheduledTime,
    this.takenTime,
    this.taken = false,
    this.skipped = false,
  });
}
