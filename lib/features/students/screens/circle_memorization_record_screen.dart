import 'package:flutter/material.dart';
import 'package:myhalaqat/features/students/services/memorization_service.dart';

class CircleMemorizationRecordScreen extends StatefulWidget {
  final int circleId;
  final String circleName;

  const CircleMemorizationRecordScreen({
    Key? key,
    required this.circleId,
    required this.circleName,
  }) : super(key: key);

  @override
  State<CircleMemorizationRecordScreen> createState() => _CircleMemorizationRecordScreenState();
}

class _CircleMemorizationRecordScreenState extends State<CircleMemorizationRecordScreen> {
  final MemorizationService _memorizationService = MemorizationService();
  bool _isLoading = true;
  List<dynamic> _records = [];
  String _selectedDate = ''; // فارغ يعني عرض الكل

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    final data = await _memorizationService.getCircleMemorizationRecord(
      widget.circleId, 
      date: _selectedDate.isEmpty ? null : _selectedDate
    );
    if (mounted) {
      setState(() {
        _records = data;
        _isLoading = false;
      });
    }
  }

  // دالة اختيار التاريخ للفلترة
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.toIso8601String().split('T')[0];
      });
      _fetchRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('سجل حفظ: ${widget.circleName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        actions: [
          if (_selectedDate.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              tooltip: 'إلغاء الفلتر',
              onPressed: () {
                setState(() => _selectedDate = '');
                _fetchRecords();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // --- شريط الفلترة ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('فلترة بالتاريخ:', style: TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_selectedDate.isEmpty ? 'عرض الكل' : _selectedDate),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectedDate.isEmpty ? Colors.grey.shade700 : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // --- قائمة السجلات ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchRecords,
                    child: _records.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _records.length,
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              return _buildRecordCard(record);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    Color resultColor;
    String resultText;
    
    switch (record['result']) {
      case 'excellent':
        resultColor = Colors.green;
        resultText = 'ممتاز';
        break;
      case 'good':
        resultColor = Colors.orange;
        resultText = 'جيد';
        break;
      case 'redo':
        resultColor = Colors.red;
        resultText = 'إعادة';
        break;
      default:
        resultColor = Colors.grey;
        resultText = 'غير محدد';
    }

    String typeText = record['type'] == 'new' ? 'حفظ جديد' : 'مراجعة';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: resultColor.withOpacity(0.3), width: 1),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record['student_name'] ?? 'بدون اسم',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    resultText,
                    style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'سورة ${record['surah_name'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text('الآيات: ${record['from_ayah']} - ${record['to_ayah']}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(typeText, style: const TextStyle(color: Colors.blue, fontSize: 11)),
                ),
                Text(
                  record['date'] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedDate.isEmpty 
              ? 'لا توجد سجلات حفظ لهذه الحلقة' 
              : 'لا توجد سجلات في هذا التاريخ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}