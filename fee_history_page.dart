import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class FeeHistoryPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final String className; // Added to catch real class name
  const FeeHistoryPage({Key? key, required this.student, required this.className}) : super(key: key);

  @override
  State<FeeHistoryPage> createState() => _FeeHistoryPageState();
}

class _FeeHistoryPageState extends State<FeeHistoryPage> {
  late Map<String, dynamic> feeHistory;
  late Map<String, dynamic> currentStudent;

  @override
  void initState() {
    super.initState();
    currentStudent = widget.student;
    _loadHistory();
  }

  void _loadHistory() {
    Map<String, dynamic> rawHistory = jsonDecode(currentStudent['feeStatus'] ?? '{}');
    setState(() {
      feeHistory = Map.fromEntries(rawHistory.entries.where((e) => e.value != 'unpaid'));
    });
  }

  Future<void> _deleteAllHistory() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Clear All Records?"),
          ],
        ),
        content: const Text("This will permanently delete the entire fee history for this student. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Map<String, dynamic> updatedStudent = Map<String, dynamic>.from(currentStudent);
      updatedStudent['feeStatus'] = jsonEncode({});
      await DatabaseHelper.instance.updateStudent(updatedStudent);
      setState(() {
        currentStudent = updatedStudent;
        feeHistory = {};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fee history cleared successfully"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _deleteFeeRecord(String monthKey) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record?"),
        content: Text("Remove the fee record for $monthKey?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      Map<String, dynamic> mutableHistory = jsonDecode(currentStudent['feeStatus'] ?? '{}');
      mutableHistory.remove(monthKey);
      Map<String, dynamic> updatedStudent = Map<String, dynamic>.from(currentStudent);
      updatedStudent['feeStatus'] = jsonEncode(mutableHistory);
      await DatabaseHelper.instance.updateStudent(updatedStudent);
      setState(() {
        currentStudent = updatedStudent;
        _loadHistory();
      });
    }
  }

  // PDF Layout Helper to avoid repeating code for Student/Office copies
  // PDF Layout Helper with better spacing for half-page printing
  pw.Widget _buildVoucherSide(String title, String schoolName, pw.MemoryImage? logoImage, Map<String, dynamic> printData) {
    return pw.Container(
      height: 380, // Forces each copy to occupy roughly half of the A4 page height
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 55, height: 55,
                  decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover)),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(schoolName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(title, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: pw.BorderRadius.circular(5)
            ),
            child: pw.Column(children: [
              _pdfRow("Roll Number:", currentStudent['rollNo']),
              _pdfRow("Student Name:", currentStudent['name']),
              _pdfRow("Father Name:", currentStudent['fatherName']),
              _pdfRow("Class Name:", widget.className),
              _pdfRow("Fee Paid:", "Rs. ${currentStudent['monthlyFee']}"),
              _pdfRow("Phone Number:", currentStudent['phone']),
            ]),
          ),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            headers: ['Month', 'Status', 'Payment Date'],
            data: printData.entries.map((e) => [e.key, "PAID", e.value]).toList(),
          ),
          pw.Spacer(), // Pushes signatures to the bottom of this voucher section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 9)),
              pw.Text("Signature: ________________", style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(bool isCurrentMonthOnly) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();
    final schoolName = prefs.getString('schoolName') ?? "Skoolio Management";
    final logoPath = prefs.getString('schoolLogo');
    pw.MemoryImage? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
    }

    final String monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    Map<String, dynamic> printData = isCurrentMonthOnly
        ? (feeHistory.containsKey(monthKey) ? {monthKey: feeHistory[monthKey]} : {})
        : feeHistory;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0), // Maximize space for half-page layout
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // STUDENT COPY (TOP)
              _buildVoucherSide("STUDENT COPY", schoolName, logoImage, printData),

              // THE DASHED CUT LINE
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.Row(
                  children: List.generate(40, (index) => pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 2, right: 2),
                      child: pw.Container(height: 1, color: PdfColors.grey400),
                    ),
                  )),
                ),
              ),
              pw.Center(
                  child: pw.Text("--- SCISSOR CUT HERE ---", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500))
              ),

              // OFFICE COPY (BOTTOM)
              _buildVoucherSide("OFFICE COPY", schoolName, logoImage, printData),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
        pw.Text(value.toString(), style: const pw.TextStyle(fontSize: 9)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fee History"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), tooltip: "Delete All History", onPressed: feeHistory.isEmpty ? null : _deleteAllHistory),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: feeHistory.isEmpty ? null : () => _showExportOptions(context))
        ],
      ),
      body: feeHistory.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]), const SizedBox(height: 10), const Text("No fee records found.", style: TextStyle(color: Colors.grey))]))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feeHistory.length,
        itemBuilder: (context, index) {
          String key = feeHistory.keys.elementAt(index);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.teal),
              title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Paid on: ${feeHistory[key]}"),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteFeeRecord(key)),
            ),
          );
        },
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Export History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.calendar_month, color: Color(0xFF1A237E)), title: const Text("This Month Only"), onTap: () { Navigator.pop(ctx); _generatePdf(true); }),
            ListTile(leading: const Icon(Icons.history, color: Color(0xFF1A237E)), title: const Text("Full History"), onTap: () { Navigator.pop(ctx); _generatePdf(false); }),
          ],
        ),
      ),
    );
  }
}