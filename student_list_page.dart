import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'student_detail_page.dart';
import 'add_student_page.dart';

class StudentListPage extends StatefulWidget {
  final int classId;
  final String className;

  const StudentListPage({Key? key, required this.classId, required this.className}) : super(key: key);

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool isLocked = false;

  String searchQuery = "";
  final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final String monthKey = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
    _loadStudents();
  }

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLocked = prefs.getBool('lock_${widget.classId}_$todayKey') ?? false;
    });
  }

  Future<void> _submitAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_${widget.classId}_$todayKey', true);
    setState(() => isLocked = true);
    _showSimpleToast("Attendance submitted successfully!");
  }

  Future<void> _loadStudents() async {
    final data = await DatabaseHelper.instance.getStudentsByClass(widget.classId);
    setState(() {
      allStudents = data;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filteredStudents = allStudents.where((student) {
        return student['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _updateStatus(Map<String, dynamic> student, String keyType, String dateKey, String status) async {
    if (isLocked && keyType == 'attendance') {
      _showSimpleToast("Attendance is locked. Edit in student profile.");
      return;
    }

    Map<String, dynamic> mutableStudent = Map<String, dynamic>.from(student);
    Map<String, dynamic> currentData = jsonDecode(mutableStudent[keyType] ?? '{}');

    if (keyType == 'feeStatus') {
      // Check if it's already marked paid for the month
      if (currentData[dateKey] != null && currentData[dateKey] != 'unpaid') {
        _showSimpleToast("Fee already marked for this month");
        return;
      }
      // NEW LOGIC: Override the status word to actually save the EXACT CURRENT DATE
      status = todayKey;
    }

    currentData[dateKey] = status;
    mutableStudent[keyType] = jsonEncode(currentData);
    await DatabaseHelper.instance.updateStudent(mutableStudent);
    _loadStudents();
  }

  void _showSimpleToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.className, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) { searchQuery = val; _applyFilters(); },
              decoration: InputDecoration(
                hintText: 'Search Name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: allStudents.isEmpty
                ? _buildEmptyStudentState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final attendance = jsonDecode(student['attendance'] ?? '{}');
                final feeStatus = jsonDecode(student['feeStatus'] ?? '{}');

                // NEW CHECK: Check if the value is recorded AND not 'unpaid'
                bool isPaid = feeStatus[monthKey] != null && feeStatus[monthKey] != 'unpaid';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${student['rollNo']}. ${student['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF1A237E), size: 20),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentDetailPage(student: student, className: widget.className))
                                ).then((refresh) {
                                  if (refresh == true) {
                                    _loadStudents(); // Reloads data from DB
                                  }
                                });
                              },
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _actionBtn("P", Colors.green, attendance[todayKey] == 'present', () => _updateStatus(student, 'attendance', todayKey, 'present')),
                                  const SizedBox(width: 8),
                                  _actionBtn("A", Colors.red, attendance[todayKey] == 'absent', () => _updateStatus(student, 'attendance', todayKey, 'absent')),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateStatus(student, 'feeStatus', monthKey, 'paid'),
                                  icon: Icon(isPaid ? Icons.check_circle : Icons.payments, size: 16),
                                  label: Text(isPaid ? "Paid" : "Pay Fee"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPaid ? Colors.teal : Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: ElevatedButton(
              onPressed: isLocked ? null : _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? Colors.grey : const Color(0xFF1A237E),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(isLocked ? "ATTENDANCE MARKED" : "SUBMIT ATTENDANCE", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStudentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.orange.withOpacity(0.4)),
          const SizedBox(height: 15),
          const Text(
            "This class is empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 25),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentPage())).then((_) => _loadStudents());
            },
            icon: const Icon(Icons.add, color: Color(0xFF1A237E)),
            label: const Text("Add Students", style: TextStyle(color: Color(0xFF1A237E))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1A237E)),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.1),
          border: Border.all(color: active ? color : Colors.transparent),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 16))),
      ),
    );
  }
}