import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/dose_log.dart';
import '../services/barcode_service.dart';
import '../services/storage_service.dart';

/// Full-screen alarm surface launched by the notification's full-screen
/// intent (Android) or by tapping the notification (iOS). Mirrors the
/// "แจ้งเตือนการกินยา" card — but "กินแล้ว" opens the camera instead of
/// instantly marking the dose taken. Marking taken only happens after a
/// matching barcode scan: the "physical-proof anti-cheat".
class ReminderAlarmScreen extends StatefulWidget {
  final DoseLog doseLog;
  const ReminderAlarmScreen({super.key, required this.doseLog});

  @override
  State<ReminderAlarmScreen> createState() => _ReminderAlarmScreenState();
}

enum _Stage { prompt, scanning, confirmed, mismatch }

class _ReminderAlarmScreenState extends State<ReminderAlarmScreen> {
  _Stage _stage = _Stage.prompt;

  void _snooze() => Navigator.pop(context);
  // NOTE: wire this to NotificationService with a short one-off delay
  // (e.g. zonedSchedule +10 minutes) if you want a real snooze timer.

  void _startScan() => setState(() => _stage = _Stage.scanning);

  Future<void> _onDetect(BarcodeCapture capture) async {
    final storage = context.read<StorageService>();
    final medicine = storage.medicineById(widget.doseLog.medicineId);
    final code = BarcodeService.extractFirstCode(capture);
    if (code == null || medicine == null) return;

    final ok = BarcodeService.verify(scanned: code, expected: medicine.verificationCode);
    if (ok) {
      await storage.markTaken(widget.doseLog.id);
      setState(() => _stage = _Stage.confirmed);
    } else {
      setState(() => _stage = _Stage.mismatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final medicine = storage.medicineById(widget.doseLog.medicineId);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: switch (_stage) {
            _Stage.prompt => _promptCard(medicine),
            _Stage.scanning => _scanCard(),
            _Stage.mismatch => _mismatchCard(),
            _Stage.confirmed => _confirmedCard(),
          },
        ),
      ),
    );
  }

  Widget _promptCard(medicine) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('แจ้งเตือนการกินยา', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text('วันนี้, ${DateFormat('HH:mm').format(widget.doseLog.scheduledTime)} น.'),
      const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.medication),
        title: Text(medicine?.name ?? ''),
        subtitle: Text(
          '${medicine?.quantityPerDose ?? ''} ${medicine?.type ?? ''}\n'
          '${medicine?.timeSlots.join(', ') ?? ''}',
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: _snooze, child: const Text('เลื่อน'))),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: _startScan, // scan-to-dismiss, not an instant tick
            child: const Text('กินแล้ว ✓'),
          ),
        ),
      ]),
    ]);
  }

  Widget _scanCard() {
    return SizedBox(
      height: 320,
      width: 280,
      child: Column(children: [
        const Text('สแกนรหัสบนขวดยาเพื่อยืนยัน', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(child: MobileScanner(onDetect: _onDetect)),
      ]),
    );
  }

  Widget _mismatchCard() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error, color: Colors.red, size: 64),
      const SizedBox(height: 12),
      const Text('รหัสไม่ตรงกับยานี้ ลองอีกครั้ง'),
      const SizedBox(height: 12),
      FilledButton(onPressed: _startScan, child: const Text('สแกนอีกครั้ง')),
    ]);
  }

  Widget _confirmedCard() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('แจ้งเตือนการกินยา', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text('วันนี้, ${DateFormat('HH:mm').format(widget.doseLog.scheduledTime)} น.'),
      const SizedBox(height: 16),
      const Icon(Icons.check_circle, color: Colors.green, size: 96),
      const SizedBox(height: 8),
      const Text('บันทึกเรียบร้อย', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
    ]);
  }
}
