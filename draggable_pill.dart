import 'dart:io';
import 'package:flutter/material.dart';

/// A floating pill icon the user can drag onto a [TimeSlotTarget] to
/// assign it to Morning/Afternoon/Evening — the "Interactive Visual
/// Inventory (Drag & Drop UI)" requirement.
class DraggablePill extends StatelessWidget {
  final String imagePath;
  final String label;
  const DraggablePill({super.key, required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(radius: 32, backgroundImage: FileImage(File(imagePath)));
    return Draggable<String>(
      data: label,
      feedback: Material(color: Colors.transparent, child: avatar),
      childWhenDragging: Opacity(opacity: 0.3, child: avatar),
      child: Column(children: [avatar, Text(label, style: const TextStyle(fontSize: 12))]),
    );
  }
}
