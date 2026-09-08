import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/medicine.dart';
import '../models/dose_log.dart';

/// The only place the app touches persistence. Everything lives in Hive
/// boxes inside the app's own sandboxed documents directory — no network
/// calls are made anywhere in this class, ever.
class StorageService extends ChangeNotifier {
  static const _medicineBox = 'medicines';
  static const _doseLogBox = 'dose_logs';

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    Hive.registerAdapter(MedicineAdapter());
    Hive.registerAdapter(DoseLogAdapter());
    await Hive.openBox<Medicine>(_medicineBox);
    await Hive.openBox<DoseLog>(_doseLogBox);
  }

  Box<Medicine> get _medicines => Hive.box<Medicine>(_medicineBox);
  Box<DoseLog> get _doseLogs => Hive.box<DoseLog>(_doseLogBox);

  List<Medicine> get allMedicines => _medicines.values.toList();

  Future<void> saveMedicine(Medicine m) async {
    await _medicines.put(m.id, m);
    notifyListeners();
  }

  Future<void> deleteMedicine(String id) async {
    await _medicines.delete(id);
    final related = _doseLogs.values.where((l) => l.medicineId == id).toList();
    for (final l in related) {
      await l.delete();
    }
    notifyListeners();
  }

  Medicine? medicineById(String id) => _medicines.get(id);

  // ---- Dose logs / calendar ----

  List<DoseLog> logsForDay(DateTime day) {
    return _doseLogs.values.where((l) =>
        l.scheduledTime.year == day.year &&
        l.scheduledTime.month == day.month &&
        l.scheduledTime.day == day.day).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<void> upsertDoseLog(DoseLog log) async {
    await _doseLogs.put(log.id, log);
    notifyListeners();
  }

  Future<void> markTaken(String doseLogId) async {
    final log = _doseLogs.get(doseLogId);
    if (log == null) return;
    log.taken = true;
    log.takenTime = DateTime.now();
    await log.save();
    notifyListeners();
  }
}
