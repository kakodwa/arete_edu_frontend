import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class StudentGradesScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final bool isSchoolAdmin;

  const StudentGradesScreen({super.key, required this.student, this.isSchoolAdmin = false});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  List<dynamic> _grades = [];
  bool _isLoading = true;
  String _selectedClassLevel = 'All Classes';
  String _selectedTerm = 'All Terms';

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  void _fetchGrades() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('schools/students/${widget.student['id']}/');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _grades = data['grades'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showAddGradeDialog() {
    final classCtrl = TextEditingController(text: widget.student['current_grade_level'] ?? 'Form 1');
    final subjectCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String selectedTerm = 'TERM_1';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Post Grade for ${widget.student['first_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Class / Form (e.g. Form 1, Standard 8)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject (e.g. Mathematics, English)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Score % (0 - 100)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedTerm,
                items: const [
                  DropdownMenuItem(value: 'TERM_1', child: Text('Term 1')),
                  DropdownMenuItem(value: 'TERM_2', child: Text('Term 2')),
                  DropdownMenuItem(value: 'TERM_3', child: Text('Term 3')),
                  DropdownMenuItem(value: 'MOCK', child: Text('National Mock Exams')),
                  DropdownMenuItem(value: 'FINAL', child: Text('Final Promotional Exam')),
                ],
                onChanged: (v) => selectedTerm = v!,
                decoration: const InputDecoration(labelText: 'Assessment / Term', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(labelText: 'Teacher Remarks (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            onPressed: () async {
              final scoreVal = double.tryParse(scoreCtrl.text.trim()) ?? 0.0;
              Navigator.pop(ctx);
              final res = await ApiService.post('schools/grades/', {
                'student': widget.student['id'],
                'class_level': classCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'term': selectedTerm,
                'score': scoreVal,
                'teacher_remarks': remarksCtrl.text.trim(),
                'academic_year': '2026/2027',
              });
              if (res.statusCode == 201) {
                _fetchGrades();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${res.body}')),
                );
              }
            },
            child: const Text('Post Mark'),
          ),
        ],
      ),
    );
  }

  // Filter and group grades by Class and Term
  List<dynamic> _getFilteredGrades() {
    return _grades.where((g) {
      final classMatches = _selectedClassLevel == 'All Classes' || (g['class_level'] ?? 'Form 1') == _selectedClassLevel;
      final termMatches = _selectedTerm == 'All Terms' || g['term'] == _selectedTerm;
      return classMatches && termMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredGrades();

    // Compute Overall Statistics
    double totalScore = 0;
    int count = filtered.length;
    for (var g in filtered) {
      totalScore += double.tryParse(g['score'].toString()) ?? 0;
    }
    final double averageScore = count > 0 ? (totalScore / count) : 0;

    String overallGrade = '-';
    if (count > 0) {
      if (averageScore >= 80) {
        overallGrade = 'Distinction (A*)';
      } else if (averageScore >= 70) {
        overallGrade = 'Very Good (A)';
      } else if (averageScore >= 60) {
        overallGrade = 'Good Pass (B)';
      } else if (averageScore >= 50) {
        overallGrade = 'Pass (C)';
      } else {
        overallGrade = 'Needs Improvement';
      }
    }

    // Extract unique classes and terms for tabs/filters
    final classes = {'All Classes', ..._grades.map((e) => (e['class_level'] ?? 'Form 1').toString())}.toList();
    final terms = {'All Terms', 'TERM_1', 'TERM_2', 'TERM_3', 'MOCK', 'FINAL'}.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkSlate,
        title: Text(
          '${widget.student['first_name']} ${widget.student['last_name']} - Report Card',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchGrades),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Soft Hero Profile Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primaryTeal.withOpacity(0.12),
                              child: Text(
                                '${widget.student['first_name'][0]}',
                                style: const TextStyle(color: AppColors.primaryTeal, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.student['first_name']} ${widget.student['last_name']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Student ID: ${widget.student['student_id_number']} • ${widget.student['current_grade_level']}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Overall Grade & Summary Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Subjects', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Container(height: 24, width: 1, color: Colors.grey.shade300),
                              Column(
                                children: [
                                  const Text('Average', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${averageScore.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryTeal),
                                  ),
                                ],
                              ),
                              Container(height: 24, width: 1, color: Colors.grey.shade300),
                              Column(
                                children: [
                                  const Text('Overall Standing', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    overallGrade,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentOrange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filters Bar for Class & Term
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedClassLevel,
                              isExpanded: true,
                              items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() => _selectedClassLevel = v!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTerm,
                              isExpanded: true,
                              items: terms.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '), style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() => _selectedTerm = v!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Soft Card with Results Table
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$_selectedClassLevel • ${_selectedTerm.replaceAll('_', ' ')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkSlate),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Verified Report', style: TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),

                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36.0),
                            child: Center(
                              child: Text('No subject marks found for the selected filter.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3.0),
                              1: FlexColumnWidth(1.2),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(2.0),
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              // Header Row
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                children: const [
                                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                ],
                              ),
                              // Data Rows
                              ...filtered.map((g) {
                                return TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(g['subject'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text('${g['score']}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTeal)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentOrange.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${g['grade_letter'] ?? '-'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentOrange),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        g['teacher_remarks'] != null && g['teacher_remarks'].toString().isNotEmpty
                                            ? g['teacher_remarks']
                                            : 'Pass',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: widget.isSchoolAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Subject Mark'),
              onPressed: _showAddGradeDialog,
            )
          : null,
    );
  }
}
