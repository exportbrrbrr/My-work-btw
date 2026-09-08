import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Detail / edit view — mirrors the "แก้ไขรายการยา" screenshot: a pill
/// photo up top and a stack of editable rows, each with a pencil icon.
class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Medicine _m = widget.medicine;

  Future<void> _editText({
    required String title,
    required String initial,
    required ValueChanged<String> onSaved,
    TextInputType? keyboardType,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              autofocus: true,
              decoration: InputDecoration(labelText: title, border: const OutlineInputBorder()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, ctrl.text),
          ),
        ]),
      ),
    );
    if (result != null) {
      setState(() => onSaved(result));
      await _persist();
    }
  }

  Future<void> _editEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _m.endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _m.endDate = picked);
      await _persist();
    }
  }

  Future<void> _persist() async {
    await context.read<StorageService>().saveMedicine(_m);
    await NotificationService.cancelForMedicine(_m);
    await NotificationService.scheduleForMedicine(_m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แก้ไขรายการยา: ${_m.name}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: _m.imagePath != null ? FileImage(File(_m.imagePath!)) : null,
            ),
          ),
          const SizedBox(height: 24),
          _row(Icons.medication_outlined, _m.name,
              () => _editText(title: 'ชื่อยา', initial: _m.name, onSaved: (v) => _m.name = v)),
          _row(Icons.local_pharmacy_outlined, 'ประเภท: ${_m.type}',
              () => _editText(title: 'ประเภท', initial: _m.type, onSaved: (v) => _m.type = v)),
          _row(
              Icons.filter_2_outlined,
              'กิน: ${_m.quantityPerDose} เม็ด',
              () => _editText(
                    title: 'กินกี่เม็ด',
                    initial: _m.quantityPerDose.toString(),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _m.quantityPerDose = int.tryParse(v) ?? _m.quantityPerDose,
                  )),
          _row(
              Icons.access_time,
              'ช่วงเวลา: ${_m.timeSlots.join(', ')}',
              () => _editText(
                    title: 'ช่วงเวลา',
                    initial: _m.timeSlots.join(', '),
                    onSaved: (v) => _m.timeSlots = v.split(',').map((e) => e.trim()).toList(),
                  )),
          _row(
              Icons.event_busy_outlined,
              'กินถึงวันที่: ${_m.endDate == null ? 'ไม่กำหนด' : DateFormat('d MMM yyyy').format(_m.endDate!)}',
              _editEndDate),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('เสร็จแล้ว'),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback onEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
      ),
    );
  }
}
