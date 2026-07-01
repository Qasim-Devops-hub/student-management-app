import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SchoolInfoPage extends StatefulWidget {
  const SchoolInfoPage({Key? key}) : super(key: key);

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('schoolName') ?? '';
      String? logoPath = prefs.getString('schoolLogo');
      if (logoPath != null) _logoFile = File(logoPath);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoFile = File(image.path));
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schoolName', _nameCtrl.text);
    if (_logoFile != null) await prefs.setString('schoolLogo', _logoFile!.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School Information Updated!"), backgroundColor: Colors.teal),
      );
      Navigator.pop(context, true); // Return true to refresh home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("School Information"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                backgroundImage: _logoFile != null ? FileImage(_logoFile!) : null,
                child: _logoFile == null ? const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF1A237E)) : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Tap to upload School Logo", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: "School Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.school, color: Color(0xFF1A237E)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("SAVE INFORMATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}