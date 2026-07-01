import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final Map<String, dynamic> student;
  const AttendanceHistoryPage({Key? key, required this.student}) : super(key: key);

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  late Map<String, dynamic> attendanceMap;

  @override
  void initState() {
    super.initState();
    attendanceMap = jsonDecode(widget.student['attendance'] ?? '{}');
  }

  Future<void> _deleteHistory() async {
    bool confirm = await _showConfirmDialog();
    if (confirm) {
      Map<String, dynamic> updated = Map<String, dynamic>.from(widget.student);
      updated['attendance'] = '{}';
      await DatabaseHelper.instance.updateStudent(updated);
      setState(() => attendanceMap = {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance history deleted successfully")));
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Attendance?"),
        content: const Text("Are you sure you want to delete all attendance records?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm Delete", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'leave': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedDates = attendanceMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: _deleteHistory)
        ],
      ),
      body: attendanceMap.isEmpty
          ? const Center(child: Text("No records available."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          String dateKey = sortedDates[index];
          String status = attendanceMap[dateKey];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Icon(Icons.event, color: _getStatusColor(status)),
              title: Text(DateFormat('EEEE, MMM dd, yyyy').format(DateTime.parse(dateKey))),
              trailing: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}