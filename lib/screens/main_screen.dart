import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../widgets/medicine_card.dart';
import 'manual_add_screen.dart';
import 'photo_scan_screen.dart';
import 'medicine_detail_screen.dart';

/// "รายการยาของฉัน" — the home tab. Matches the empty state
/// ("เพิ่มยาก่อน"), the populated list of medicine cards, and the
/// expanding two-button (+รูปภาพ / manual) FAB menu from the screenshots.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final medicines = storage.allMedicines;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการยาของฉัน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          medicines.isEmpty
              ? const Center(
                  child: Text('เพิ่มยาก่อน', style: TextStyle(color: Colors.black26, fontSize: 20)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medicines.length,
                  itemBuilder: (context, i) => MedicineCard(
                    medicine: medicines[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MedicineDetailScreen(medicine: medicines[i])),
                    ),
                  ),
                ),
          if (_menuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _menuOpen = false),
                child: Container(color: Colors.transparent),
              ),
            ),
          if (_menuOpen) _buildExpandedMenu(context),
        ],
      ),
      floatingActionButton: _menuOpen
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _menuOpen = true),
              child: const Icon(Icons.add),
            ),
    );
  }

  /// The two extra blue buttons that appear above the FAB: "รูปภาพ"
  /// (photo / label-OCR flow) and "manual" (the plain form), plus a
  /// close (X) button — mirrors the expanded-FAB screenshot exactly.
  Widget _buildExpandedMenu(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _menuButton(
            label: 'รูปภาพ',
            icon: Icons.image,
            heroTag: 'photo',
            onTap: () {
              setState(() => _menuOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoScanScreen()));
            },
          ),
          const SizedBox(height: 16),
          _menuButton(
            label: 'manual',
            icon: Icons.assignment,
            heroTag: 'manual',
            onTap: () {
              setState(() => _menuOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualAddScreen()));
            },
          ),
          const SizedBox(height: 16),
          _menuButton(
            label: '',
            icon: Icons.close,
            heroTag: 'close',
            background: Colors.blue.shade700,
            onTap: () => setState(() => _menuOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
    Color? background,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 12),
        ],
        FloatingActionButton(
          heroTag: heroTag,
          backgroundColor: background ?? Colors.blue,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}
