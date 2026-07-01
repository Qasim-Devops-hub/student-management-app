import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'database_helper.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({Key? key}) : super(key: key);

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedClassId;

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _feeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();

  void _saveStudent() async {
    if (!_formKey.currentState!.validate() || _selectedClassId == null) {
      _showMessage('Please select a class and fill all required fields.', isError: true);
      return;
    }

    try {
      await DatabaseHelper.instance.insertStudent({
        'classId': _selectedClassId,
        'name': _nameController.text,
        'fatherName': _fatherNameController.text,
        'rollNo': _rollNoController.text,
        'monthlyFee': double.parse(_feeController.text),
        'phone': _phoneController.text,
        'description': _descController.text,
        'attendance': '{}',
        'feeStatus': '{}',
      });
      _showMessage('Student enrolled successfully!', isError: false);
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Error adding student.', isError: true);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Enroll New Student', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Matching Indigo Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
                SizedBox(height: 8),
                Text('Fill in the student profile details', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              decoration: _inputDecoration('Assigned Class', Icons.school_rounded),
                              initialValue: _selectedClassId,
                              items: provider.classes.map((cls) {
                                return DropdownMenuItem<int>(
                                  value: cls['id'],
                                  child: Text('${cls['name']} (${cls['section']})'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedClassId = val),
                              validator: (v) => v == null ? 'Please select a class' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(_nameController, 'Student Full Name', Icons.person),
                            const SizedBox(height: 16),
                            _buildField(_fatherNameController, 'Father\'s Name', Icons.family_restroom),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildField(_rollNoController, 'Roll No', Icons.tag)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildField(_feeController, 'Monthly Fee', Icons.attach_money, isNum: true)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildField(_phoneController, 'Contact Number', Icons.phone, isPhone: true),
                            const SizedBox(height: 16),
                            _buildField(_descController, 'Description (Optional)', Icons.description, lines: 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                      child: const Text('ENROLL STUDENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Professional Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('Skoolio • Student Enrollment System', style: TextStyle(color: Colors.grey, fontSize: 11)),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF3949AB)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNum = false, bool isPhone = false, int lines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: lines,
      keyboardType: isNum ? TextInputType.number : (isPhone ? TextInputType.phone : TextInputType.text),
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}