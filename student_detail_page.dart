import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'fee_history_page.dart';
import 'attendance_history_page.dart';

class StudentDetailPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final String className;
  const StudentDetailPage({Key? key, required this.student, required this.className}) : super(key: key);

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  bool isEditing = false;
  late Map<String, dynamic> _currentStudent;
  late TextEditingController _nameCtrl, _rollCtrl, _phoneCtrl, _feeCtrl, _fNameCtrl, _descCtrl;

  String _editAttendanceStatus = '';
  String _editFeeStatus = '';

  final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final String monthKey = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _currentStudent = Map<String, dynamic>.from(widget.student);
    _initControllers();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _currentStudent['name']);
    _fNameCtrl = TextEditingController(text: _currentStudent['fatherName']);
    _rollCtrl = TextEditingController(text: _currentStudent['rollNo']);
    _phoneCtrl = TextEditingController(text: _currentStudent['phone']);
    _feeCtrl = TextEditingController(text: _currentStudent['monthlyFee'].toString());
    _descCtrl = TextEditingController(text: _currentStudent['description'] ?? '');

    final attendanceMap = jsonDecode(_currentStudent['attendance'] ?? '{}');
    final feeMap = jsonDecode(_currentStudent['feeStatus'] ?? '{}');

    _editAttendanceStatus = attendanceMap[todayKey] ?? '';
    _editFeeStatus = feeMap[monthKey] ?? 'unpaid';
  }

  Future<void> _updateData() async {
    if (_nameCtrl.text.isEmpty || _rollCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Roll No cannot be empty"), backgroundColor: Colors.orange),
      );
      return;
    }

    bool? confirm = await _showConfirmDialog("Save Changes?", "Update student profile and status?");
    if (confirm != true) return;

    try {
      Map<String, dynamic> updated = Map<String, dynamic>.from(_currentStudent);
      updated['name'] = _nameCtrl.text;
      updated['fatherName'] = _fNameCtrl.text;
      updated['rollNo'] = _rollCtrl.text;
      updated['phone'] = _phoneCtrl.text;
      updated['monthlyFee'] = double.parse(_feeCtrl.text);
      updated['description'] = _descCtrl.text;

      Map<String, dynamic> attMap = jsonDecode(updated['attendance'] ?? '{}');
      if (_editAttendanceStatus.isNotEmpty) attMap[todayKey] = _editAttendanceStatus;
      updated['attendance'] = jsonEncode(attMap);

      Map<String, dynamic> feeMap = jsonDecode(updated['feeStatus'] ?? '{}');
      feeMap[monthKey] = _editFeeStatus;
      updated['feeStatus'] = jsonEncode(feeMap);

      await DatabaseHelper.instance.updateStudent(updated);

      if (mounted) {
        setState(() {
          _currentStudent = updated;
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Changes Saved Successfully!"),
              ],
            ),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteStudent() async {
    bool? confirm = await _showConfirmDialog("Delete Student?", "This will permanently remove this student record.", isDestructive: true);
    if (confirm == true) {
      await DatabaseHelper.instance.deleteStudent(_currentStudent['id']);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content, {bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isDestructive ? Colors.red : const Color(0xFF1A237E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isDestructive ? "Delete" : "Save", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feeMap = jsonDecode(_currentStudent['feeStatus'] ?? '{}') as Map<String, dynamic>;
    // THE FIX: Check if it exists AND is not unpaid, rather than exactly 'paid'
    bool isPaid = feeMap[monthKey] != null && feeMap[monthKey] != 'unpaid';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(isEditing ? "Edit Profile" : "Student Profile"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
          actions: [
            if (!isEditing) ...[
              IconButton(icon: const Icon(Icons.edit_note), onPressed: () => setState(() => isEditing = true)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: _deleteStudent),
            ] else
              IconButton(icon: const Icon(Icons.check), onPressed: _updateData),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 30, top: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(radius: 45, backgroundColor: Colors.white, child: Icon(Icons.person, size: 55, color: Color(0xFF1A237E))),
                          const SizedBox(height: 12),
                          Text(_currentStudent['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Text("Class: ${widget.className}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isPaid ? Colors.teal.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              border: Border.all(color: isPaid ? Colors.teal : Colors.redAccent, width: 1.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isPaid ? Icons.check_circle : Icons.error_outline, color: isPaid ? Colors.teal : Colors.redAccent),
                                const SizedBox(width: 10),
                                Text(
                                  "${DateFormat('MMMM').format(DateTime.now())} Fee: ${isPaid ? 'PAID' : 'NOT PAID'}",
                                  style: TextStyle(color: isPaid ? Colors.teal.shade800 : Colors.redAccent.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          if (isEditing) _buildEditForm() else _buildViewProfile(),
                          const SizedBox(height: 25),
                          const Text("Management History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _historyActionBtn("Fee History", Icons.account_balance_wallet, Colors.orange.shade800, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => FeeHistoryPage(student: _currentStudent,className: widget.className))).then((_) => setState(() {}));
                              })),
                              const SizedBox(width: 12),
                              Expanded(child: _historyActionBtn("Attendance", Icons.calendar_today, Colors.teal, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceHistoryPage(student: _currentStudent))).then((_) => setState(() {}));
                              })),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewProfile() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _detailRow(Icons.tag, "Roll Number", _currentStudent['rollNo']),
            _detailRow(Icons.person_outline, "Student Name", _currentStudent['name']),
            _detailRow(Icons.family_restroom_outlined, "Father Name", _currentStudent['fatherName']),
            _detailRow(Icons.phone_android_outlined, "Phone Number", _currentStudent['phone']),
            _detailRow(Icons.school_outlined, "Class Name", widget.className),
            _detailRow(Icons.payments_outlined, "Monthly Fee", "${_currentStudent['monthlyFee']}"),
            _detailRow(Icons.description_outlined, "Description", _currentStudent['description'] ?? 'No additional notes', isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF1A237E), size: 20)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }

  Widget _buildEditForm() {
    // THE FIX: Allow the edit form to recognize our date values
    bool isMarkedPaid = _editFeeStatus != 'unpaid' && _editFeeStatus.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Status Overrides", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 15),
          _editToggleLabel("Current Month Fee Status"),
          Row(
            children: [
              Expanded(child: _statusToggle("Paid", Colors.teal, isMarkedPaid, () => setState(() => _editFeeStatus = todayKey))),
              const SizedBox(width: 10),
              Expanded(child: _statusToggle("Unpaid", Colors.redAccent, !isMarkedPaid, () => setState(() => _editFeeStatus = 'unpaid'))),
            ],
          ),
          const SizedBox(height: 20),
          _editToggleLabel("Today's Attendance Status"),
          Row(
            children: [
              Expanded(child: _statusToggle("Present", Colors.green, _editAttendanceStatus == 'present', () => setState(() => _editAttendanceStatus = 'present'))),
              const SizedBox(width: 10),
              Expanded(child: _statusToggle("Absent", Colors.red, _editAttendanceStatus == 'absent', () => setState(() => _editAttendanceStatus = 'absent'))),
            ],
          ),
          const Divider(height: 40),
          const Text("Update Personal Info", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 15),
          _editField(_rollCtrl, "Roll Number", Icons.tag),
          _editField(_nameCtrl, "Student Name", Icons.person),
          _editField(_fNameCtrl, "Father Name", Icons.family_restroom),
          _editField(_phoneCtrl, "Phone", Icons.phone, isPhone: true),
          _editField(_feeCtrl, "Fee Amount", Icons.attach_money, isNum: true),
          _editField(_descCtrl, "Description", Icons.notes, lines: 3),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _updateData,
            icon: const Icon(Icons.save),
            label: const Text("Save All Changes"),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          )
        ],
      ),
    );
  }

  Widget _editToggleLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)));

  Widget _statusToggle(String label, Color color, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? color : Colors.white, border: Border.all(color: active ? color : Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon, {bool isNum = false, bool isPhone = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        keyboardType: isNum ? TextInputType.number : (isPhone ? TextInputType.phone : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A237E), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget _historyActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}