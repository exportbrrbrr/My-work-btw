import 'package:flutter/material.dart';

/// A drop target representing one time-of-day bucket (Morning / Noon /
/// Evening) in the add-medicine flow.
class TimeSlotTarget extends StatelessWidget {
  final String label;
  final ValueChanged<String> onPillDropped;
  const TimeSlotTarget({super.key, required this.label, required this.onPillDropped});

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onPillDropped(details.data),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? Colors.blue.shade50 : Colors.grey.shade100,
            border: Border.all(
                color: active ? Colors.blue : Colors.grey.shade300,
                width: active ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label),
        );
      },
    );
  }
}
