import 'package:flutter/material.dart';
import '../widgets/draggable_pill.dart';
import '../widgets/time_slot_target.dart';

/// Optional drag-and-drop alternative to the plain dropdown in
/// ManualAddScreen: drag the just-cropped pill photo onto a
/// time-of-day bucket. Implements the "Interactive Visual Inventory
/// (Drag & Drop UI)" requirement explicitly.
class PillSortScreen extends StatefulWidget {
  final String pillImagePath;
  const PillSortScreen({super.key, required this.pillImagePath});

  @override
  State<PillSortScreen> createState() => _PillSortScreenState();
}

class _PillSortScreenState extends State<PillSortScreen> {
  final Set<String> _assigned = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลากยาไปยังช่วงเวลา')),
      body: Column(children: [
        const SizedBox(height: 24),
        DraggablePill(imagePath: widget.pillImagePath, label: 'ยานี้'),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TimeSlotTarget(
              label: 'เช้า',
              onPillDropped: (_) => setState(() => _assigned.add('เช้า')),
            ),
            TimeSlotTarget(
              label: 'กลางวัน',
              onPillDropped: (_) => setState(() => _assigned.add('กลางวัน')),
            ),
            TimeSlotTarget(
              label: 'เย็น',
              onPillDropped: (_) => setState(() => _assigned.add('เย็น')),
            ),
          ],
        ),
        if (_assigned.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('เลือกแล้ว: ${_assigned.join(', ')}'),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _assigned.isEmpty
                ? null
                : () => Navigator.pop(context, _assigned.toList()),
            child: const Text('เสร็จแล้ว'),
          ),
        ),
      ]),
    );
  }
}
