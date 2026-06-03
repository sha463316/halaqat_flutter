import 'package:flutter/material.dart';
import 'package:myhalaqat/core/theme/app_theme.dart';
import 'package:myhalaqat/core/widgets/custom_snackbar.dart';
import 'package:myhalaqat/features/students/services/student_service.dart';
import 'package:myhalaqat/features/saber/services/saber_service.dart';
import 'package:myhalaqat/features/saber/screens/saber_requests_screen.dart';
import 'package:myhalaqat/core/network/sync_manager.dart';
import 'package:myhalaqat/core/notifiers/app_notifiers.dart';

class CreateSaberRequestScreen extends StatefulWidget {
  final int circleId;
  const CreateSaberRequestScreen({Key? key, required this.circleId}) : super(key: key);

  @override
  State<CreateSaberRequestScreen> createState() => _CreateSaberRequestScreenState();
}

class _CreateSaberRequestScreenState extends State<CreateSaberRequestScreen> {
  final StudentService _studentService = StudentService();
  final SaberService _saberService = SaberService();
  bool _isLoading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _studentService.getStudentsByCircle(widget.circleId);
    if (mounted) setState(() { _students = students; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب سبر — اختر طالباً')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _students.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('${_students.length} طالباً — اختر أحدهم', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      );
                    }
                    final student = _students[i - 1];
                    return _buildStudentCard(student);
                  },
                ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showSaberForm(student),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(student['student_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaberForm(dynamic student) async {
    int selectedPart = 1;
    String quizType = 'new';
    final notesCtrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.quiz, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(student['student_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ]),
                const SizedBox(height: 20),

                const Text('الجزء *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedPart,
                  items: List.generate(30, (i) => DropdownMenuItem(value: i + 1, child: Text('الجزء ${i + 1}'))),
                  onChanged: (v) => setSheetState(() => selectedPart = v ?? 1),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.auto_stories)),
                ),
                const SizedBox(height: 16),

                const Text('النوع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _choiceChip('حفظ جديد', 'new', quizType, Icons.star, AppColors.primary, (v) => setSheetState(() => quizType = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _choiceChip('مراجعة', 'review', quizType, Icons.menu_book, AppColors.info, (v) => setSheetState(() => quizType = v))),
                ]),
                const SizedBox(height: 16),

                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'ملاحظات للمشرف (اختياري)...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('إرسال الطلب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );

    notesCtrl.dispose();
    if (saved == true) {
      final ok = await _saberService.createSaberRequest(
        enrollmentId: student['id'],
        quranPart: selectedPart,
        quizType: quizType,
        teacherNotes: notesCtrl.text,
      );

      if (mounted) {
        if (ok) {
          CustomSnackbar.show(context, message: 'تم إرسال طلب السبر بنجاح ✅', color: Colors.green, icon: Icons.check_circle);
        } else {
          CustomSnackbar.show(context, message: 'حفظ محلياً — سيرسل فور توفر الإنترنت', color: Colors.orange, icon: Icons.cloud_upload);
        }
      }
    }
  }

  Widget _choiceChip(String label, String value, String current, IconData icon, Color color, void Function(String) onChanged) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
