import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';
import 'student_grades_screen.dart';

class ClientResultsPortalScreen extends StatefulWidget {
  const ClientResultsPortalScreen({super.key});

  @override
  State<ClientResultsPortalScreen> createState() => _ClientResultsPortalScreenState();
}

class _ClientResultsPortalScreenState extends State<ClientResultsPortalScreen> {
  List<dynamic> _linkedStudents = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  // Quick lookup controllers for students without login credentials
  final _studentIdCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  bool _isSearchingId = false;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _initLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    setState(() => _isLoggedIn = token != null);

    if (token != null) {
      _fetchMyChildrenRecords();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _fetchMyChildrenRecords() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('schools/students/');
      if (res.statusCode == 200) {
        setState(() {
          _linkedStudents = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _lookupByStudentId() async {
    final id = _studentIdCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    if (id.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both your Student ID and Last Name.')),
      );
      return;
    }

    setState(() => _isSearchingId = true);
    try {
      final res = await ApiService.post('schools/students/check_results_by_id/', {
        'student_id_number': id,
        'last_name': lastName,
      });

      setState(() => _isSearchingId = false);
      if (res.statusCode == 200) {
        final studentData = jsonDecode(res.body);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentGradesScreen(student: studentData, isSchoolAdmin: false),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No student record matched that ID and Last Name.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      setState(() => _isSearchingId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 850,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Quick Student ID Lookup (Works even without login credentials!)
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_outlined, color: AppColors.accentOrange),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check Report Card by Student ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              'Enrolled directly at school? Enter the Student ID provided by your school admin.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _studentIdCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Student ID (e.g. STU-2026-A1B2C3)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Student Last Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSearchingId
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: const Text('View Student Report Card', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isSearchingId ? null : _lookupByStudentId,
                  ),
                ],
              ),
            ),

            // Section 2: Linked Account Records (For logged-in parents/students)
            if (_isLoggedIn) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Linked Account Report Cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMyChildrenRecords),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
              else if (_linkedStudents.isEmpty)
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'No records directly linked to your account phone number yet. Use the Student ID lookup above if your school gave you an ID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                ..._linkedStudents.map((s) {
                  return SoftCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentGradesScreen(student: s, isSchoolAdmin: false),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryTeal.withOpacity(0.14),
                          child: const Icon(Icons.person, color: AppColors.primaryTeal),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s['first_name']} ${s['last_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 3),
                              Text('ID: ${s['student_id_number']} • Class: ${s['current_grade_level']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              if (s['school_name'] != null)
                                Text('${s['school_name']}', style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
