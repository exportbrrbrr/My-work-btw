import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/vision_service.dart';
import '../services/notification_service.dart';
import 'barcode_register_screen.dart';
import 'pill_sort_screen.dart';

/// "เพิ่มยาแบบระบุเอง" — mirrors the manual-entry card from the
/// screenshots, plus the two additional fields requested: an end date
/// and a per-dose quantity.
class ManualAddScreen extends StatefulWidget {
  final Medicine? existing; // non-null when opened for editing
  const ManualAddScreen({super.key, this.existing});

  @override
  State<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends State<ManualAddScreen> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  String _period = 'หลังอาหารเช้า';
  DateTime? _endDate;
  String? _croppedPillPath;
  final _vision = VisionService();

  static const _periods = [
    'หลังอาหารเช้า',
    'หลังอาหารกลางวัน',
    'หลังอาหารเย็น',
    'ก่อนนอน',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    if (m != null) {
      _nameCtrl.text = m.name;
      _typeCtrl.text = m.type;
      _qtyCtrl.text = m.quantityPerDose.toString();
      _period = m.timeSlots.isNotEmpty ? m.timeSlots.first : _period;
      _endDate = m.endDate;
      _croppedPillPath = m.imagePath;
    }
  }

  @override
  void dispose() {
    _vision.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;
    final cropped = await _vision.extractPill(picked.path); // on-device only
    setState(() => _croppedPillPath = cropped);
  }

  /// Optional drag-and-drop path to choosing a time slot, wired to the
  /// "Interactive Visual Inventory" requirement.
  Future<void> _openDragSort() async {
    if (_croppedPillPath == null) return;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => PillSortScreen(pillImagePath: _croppedPillPath!)),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _period = _mapToPeriod(result.first));
    }
  }

  String _mapToPeriod(String bucket) => const {
        'เช้า': 'หลังอาหารเช้า',
        'กลางวัน': 'หลังอาหารกลางวัน',
        'เย็น': 'หลังอาหารเย็น',
      }[bucket] ?? _period;

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final storage = context.read<StorageService>();

    final medicine = widget.existing ??
        Medicine(
          id: const Uuid().v4(),
          name: '',
          type: '',
          quantityPerDose: 1,
          timeSlots: const [],
          startDate: DateTime.now(),
          alarmTimes: const [],
        );

    medicine
      ..name = _nameCtrl.text.trim()
      ..type = _typeCtrl.text.trim().isEmpty ? 'เม็ด' : _typeCtrl.text.trim()
      ..quantityPerDose = int.tryParse(_qtyCtrl.text) ?? 1
      ..timeSlots = [_period]
      ..endDate = _endDate
      ..imagePath = _croppedPillPath
      ..alarmTimes = [_defaultTimeFor(_period)];

    await storage.saveMedicine(medicine);
    await NotificationService.scheduleForMedicine(medicine);

    if (!mounted) return;
    // First-time creation asks the user to register the bottle's
    // physical barcode/QR — the "anti-cheat" match target.
    if (widget.existing == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BarcodeRegisterScreen(medicine: medicine)),
      );
    }
    if (mounted) Navigator.pop(context, medicine);
  }

  String _defaultTimeFor(String period) => const {
        'หลังอาหารเช้า': '08:00',
        'หลังอาหารกลางวัน': '12:00',
        'หลังอาหารเย็น': '18:00',
        'ก่อนนอน': '22:00',
      }[period] ?? '08:00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null ? 'เพิ่มยาแบบระบุเอง' : 'แก้ไขรายการยา')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    _croppedPillPath != null ? FileImage(File(_croppedPillPath!)) : null,
                child: _croppedPillPath == null
                    ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey))),
          if (_croppedPillPath != null)
            Center(
              child: TextButton.icon(
                onPressed: _openDragSort,
                icon: const Icon(Icons.drag_indicator, size: 18),
                label: const Text('หรือลากยาไปยังช่วงเวลา'),
              ),
            ),
          const SizedBox(height: 16),
          _field(icon: Icons.medication, controller: _nameCtrl, hint: 'ชื่อยา'),
          const SizedBox(height: 12),
          _field(icon: Icons.local_pharmacy, controller: _typeCtrl, hint: 'ประเภทยา'),
          const SizedBox(height: 12),
          _field(
            icon: Icons.pin,
            controller: _qtyCtrl,
            hint: 'กินกี่เม็ด',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _dropdownField(),
          const SizedBox(height: 12),
          _endDateField(),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('เสร็จแล้ว'),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dropdownField() {
    return DropdownButtonFormField<String>(
      value: _period,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
      onChanged: (v) => setState(() => _period = v ?? _period),
    );
  }

  // New field #1 requested: "กินถึงวันที่เท่าไหร่"
  Widget _endDateField() {
    return InkWell(
      onTap: _pickEndDate,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.event_busy),
          hintText: 'กินถึงวันที่',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(_endDate == null ? 'ไม่กำหนด' : DateFormat('d MMM yyyy').format(_endDate!)),
      ),
    );
  }
}
