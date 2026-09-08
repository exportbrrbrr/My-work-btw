import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/barcode_service.dart';
import '../services/storage_service.dart';

/// Shown once, right after a new medicine is created: links a physical
/// QR/barcode (stuck on the real bottle) to this record so a later
/// reminder can demand proof the bottle is actually in hand.
class BarcodeRegisterScreen extends StatelessWidget {
  final Medicine medicine;
  const BarcodeRegisterScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ติดรหัสยืนยันขวดยา')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('สแกน QR/บาร์โค้ดที่ติดบนขวดยาจริง เพื่อผูกกับรายการนี้'),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) async {
                final code = BarcodeService.extractFirstCode(capture);
                if (code == null) return;
                medicine.verificationCode = code;
                await context.read<StorageService>().saveMedicine(medicine);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ข้ามขั้นตอนนี้ (ตั้งค่าทีหลังได้)'),
          ),
        ],
      ),
    );
  }
}
