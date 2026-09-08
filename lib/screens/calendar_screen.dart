import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';

/// "ปฏิทินกินยา" — a per-day time grid, with a toggle to the
/// "แผนภูมิระยะเวลายา" long-term timeline view seen layered over it
/// in the screenshot.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _day = DateTime.now();
  bool _showTimeline = false;

  static const _rows = ['08:00', '12:00', '18:00', '22:00'];
  static const _cols = ['เช้า', 'กลางวัน', 'เย็น'];

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final logs = storage.logsForDay(_day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ปฏิทินกินยา'),
        actions: [
          IconButton(
            icon: Icon(_showTimeline ? Icons.calendar_view_day : Icons.view_timeline),
            tooltip: 'แผนภูมิระยะเวลายา (Long-term Medicine Timeline)',
            onPressed: () => setState(() => _showTimeline = !_showTimeline),
          ),
        ],
      ),
      body: _showTimeline ? _buildTimeline(storage) : _buildDayGrid(logs),
    );
  }

  Widget _buildDayGrid(List logs) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
            ),
            Text(DateFormat('EEE d MMMM yyyy').format(_day)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))),
            ),
          ],
        ),
        Expanded(
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.blue.shade300),
                children: _cols
                    .map((c) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(c,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
              ),
              for (final r in _rows)
                TableRow(children: _cols.map((c) => _cell(r, logs)).toList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String hour, List logs) {
    final match =
        logs.where((l) => DateFormat('HH:mm').format(l.scheduledTime) == hour).toList();
    return Container(
      height: 72,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: match.isEmpty
          ? null
          : Text(match.first.taken ? 'กินแล้ว ✓' : 'รอกิน', style: const TextStyle(fontSize: 12)),
    );
  }

  /// Long-term view: one column per day for the next two weeks, so a
  /// multi-month course can be seen end-to-end.
  Widget _buildTimeline(StorageService storage) {
    final days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            children: days
                .map((d) => Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(DateFormat('E d/M').format(d)),
                    ))
                .toList(),
          ),
          TableRow(
            children: days.map((d) {
              final count = storage.logsForDay(d).length;
              return SizedBox(
                  height: 60, child: Center(child: Text(count > 0 ? '$count doses' : '')));
            }).toList(),
          ),
        ],
      ),
    );
  }
}
