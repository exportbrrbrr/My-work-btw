import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();      // Hive boxes — 100% local
  await NotificationService.init(); // local alarm channel, no cloud push
  runApp(const MedicineReminderApp());
}

class MedicineReminderApp extends StatelessWidget {
  const MedicineReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StorageService(),
      child: MaterialApp(
        title: 'รายการยาของฉัน',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2E9BF0),
          scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        ),
        home: const RootShell(),
      ),
    );
  }
}

/// Bottom navigation shell: main / calendar / setting — mirrors the
/// three-tab bar seen in every screenshot.
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _pages = const [
    MainScreen(),
    CalendarScreen(),
    _SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'main'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'calendar'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'setting'),
        ],
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Settings'));
}
