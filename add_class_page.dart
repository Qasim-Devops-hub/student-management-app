import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'app_provider.dart';

class AddClassPage extends StatefulWidget {
  final Map<String, dynamic>? classData; // Null means Add Mode, Not Null means Update Mode

  const AddClassPage({Key? key, this.classData}) : super(key: key);

  @override
  State<AddClassPage> createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  bool isUpdateMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.classData != null) {
      isUpdateMode = true;
      _nameController.text = widget.classData!['name'];
      _sectionController.text = widget.classData!['section'];
    }
  }

  void _processClass() async {
    if (_nameController.text.isEmpty || _sectionController.text.isEmpty) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    // Confirmation for Update
    if (isUpdateMode) {
      bool? confirm = await _showConfirmUpdate();
      if (confirm != true) return;
    }

    try {
      if (isUpdateMode) {
        // UPDATE LOGIC
        await DatabaseHelper.instance.updateClass({
          'id': widget.classData!['id'],
          'name': _nameController.text,
          'section': _sectionController.text,
        });
        _showMessage('Class updated successfully!', isError: false);
      } else {
        // SAVE LOGIC
        await DatabaseHelper.instance.insertClass({
          'name': _nameController.text,
          'section': _sectionController.text,
        });
        _showMessage('Class added successfully!', isError: false);
      }

      Provider.of<AppProvider>(context, listen: false).fetchClasses(); // Refresh Home
      Navigator.pop(context); // Automatically move back to home screen
    } catch (e) {
      _showMessage('An error occurred. Please try again.', isError: true);
    }
  }

  Future<bool?> _showConfirmUpdate() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Update"),
        content: const Text("Are you sure you want to save these changes to the class?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text(isUpdateMode ? 'Update Class' : 'Add New Class', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Professional Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 40, top: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Icon(isUpdateMode ? Icons.edit_note : Icons.add_business_rounded, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(isUpdateMode ? 'Modify existing class details' : 'Register a brand new class', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputField(
                        controller: _nameController,
                        label: 'Class Name',
                        icon: Icons.class_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: _sectionController,
                        label: 'Section',
                        icon: Icons.layers_rounded,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _processClass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        child: Text(
                          isUpdateMode ? 'UPDATE CLASS' : 'SAVE CLASS',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Footer
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Classroom Pro • Management System', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3949AB)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
      ),
    );
  }
}