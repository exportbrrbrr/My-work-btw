import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/label_ocr_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/dose_log.dart';

/// "อ่านฉลากยา" — snaps the printed label, runs on-device OCR, and
/// writes the resulting schedule straight to storage + the calendar
/// without ever showing the manual form.
class PhotoScanScreen extends StatefulWidget {
  const PhotoScanScreen({super.key});
  @override
  State<PhotoScanScreen> createState() => _PhotoScanScreenState();
}

class _PhotoScanScreenState extends State<PhotoScanScreen> {
  final _ocr = LabelOcrService();
  bool _working = false;

  Future<void> _scanLabel() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() => _working = true);

    final draft = await _ocr.parseLabel(photo.path);
    final storage = context.read<StorageService>();
    await storage.saveMedicine(draft);
    await NotificationService.scheduleForMedicine(draft);

    // Populate today's calendar entries immediately so the user sees
    // "กินยาอะไร กี่โมง" with no further input required.
    for (final hhmm in draft.alarmTimes) {
      final parts = hhmm.split(':');
      final now = DateTime.now();
      final scheduled =
          DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      await storage.upsertDoseLog(DoseLog(
        id: const Uuid().v4(),
        medicineId: draft.id,
        scheduledTime: scheduled,
      ));
    }

    setState(() => _working = false);
    if (mounted) Navigator.pop(context, draft);
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อ่านฉลากยา')),
      body: Center(
        child: _working
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.document_scanner, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'ถ่ายรูปฉลากยา แล้วระบบจะอ่านชื่อยา ปริมาณ และช่วงเวลาให้อัตโนมัติ '
                    'โดยไม่ต้องกรอกฟอร์ม manual',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _scanLabel,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายรูปฉลากยา'),
                  ),
                ]),
              ),
      ),
    );
  }
}
