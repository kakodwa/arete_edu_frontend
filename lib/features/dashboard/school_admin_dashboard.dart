import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';
import '../dashboard/dashboard_dispatcher.dart';
import '../schools/school_form_screen.dart';
import '../schools/add_student_screen.dart';
import '../schools/student_grades_screen.dart';
import '../schools/grade_settings_screen.dart';

class SchoolAdminDashboard extends StatefulWidget {
  const SchoolAdminDashboard({super.key});

  @override
  State<SchoolAdminDashboard> createState() => _SchoolAdminDashboardState();
}

class _SchoolAdminDashboardState extends State<SchoolAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _mySchools = [];
  List<dynamic> _applications = [];
  List<dynamic> _enrolledStudents = [];

  bool _isLoadingSchools = true;
  bool _isLoadingApps = true;
  bool _isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  void _fetchAll() {
    _fetchMySchools();
    _fetchApplications();
    _fetchEnrolledStudents();
  }

  void _fetchMySchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final res = await ApiService.get('schools/');
      if (res.statusCode == 200) {
        setState(() {
          _mySchools = jsonDecode(res.body);
          _isLoadingSchools = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingSchools = false);
    }
  }

  void _fetchApplications() async {
    setState(() => _isLoadingApps = true);
    try {
      final res = await ApiService.get('admissions/');
      if (res.statusCode == 200) {
        setState(() {
          _applications = jsonDecode(res.body);
          _isLoadingApps = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingApps = false);
    }
  }

  void _fetchEnrolledStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final res = await ApiService.get('schools/students/');
      if (res.statusCode == 200) {
        setState(() {
          _enrolledStudents = jsonDecode(res.body);
          _isLoadingStudents = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingStudents = false);
    }
  }

  bool _isSubscriptionActive() {
    if (_mySchools.isEmpty) return false;
    final s = _mySchools.first;
    return s['is_subscription_valid'] == true || s['subscription_active'] == true;
  }

  void _renewMonthlySubscription(int schoolId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Subscribe / Renew (MWK 5,000/mo)'),
        content: const Text(
          'Unlock the Student Database & Online Gradebook module for 30 days.\n\n'
          'Monthly Plan: MWK 5,000\nPayment Method: Airtel Money / TNM Mpamba / Bank PRN.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Authorize MWK 5,000 Payment'),
          )
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.post('schools/$schoolId/subscribe/', {});
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription activated! Gradebook module unlocked for 30 days.'), backgroundColor: AppColors.successGreen),
        );
        _fetchAll();
      }
    }
  }

  void _deleteSchool(int schoolId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete School Listing?'),
        content: Text('Are you sure you want to remove "$name"? All related data will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.delete('schools/$schoolId/');
      if (res.statusCode == 204 || res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('School profile deleted.')));
        _fetchMySchools();
      }
    }
  }

  void _updateStatus(String appId, String newStatus) async {
    await ApiService.post('admissions/$appId/update_admission_status/', {'status': newStatus});
    _fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final subActive = _isSubscriptionActive();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('School Administrator Hub'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Profiles'),
            Tab(icon: Icon(Icons.assignment_ind), text: 'Admissions'),
            Tab(icon: Icon(Icons.grade), text: 'Gradebook'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Grading Scale Settings',
            onPressed: () {
              if (_mySchools.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GradeSettingsScreen(schoolId: _mySchools.first['id'])),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please register your school profile first.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardDispatcher(role: 'GUEST')));
            },
          )
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 1000,
        padding: const EdgeInsets.all(16),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Manage Schools & Subscriptions
            _isLoadingSchools
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _mySchools.isEmpty
                    ? Center(
                        child: SoftCard(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_outlined, size: 64, color: AppColors.primaryTeal),
                              const SizedBox(height: 12),
                              const Text('No School Profile Registered Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                                icon: const Icon(Icons.add),
                                label: const Text('Post Your School'),
                                onPressed: () async {
                                  final c = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const SchoolFormScreen()));
                                  if (c == true) _fetchMySchools();
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _mySchools.length,
                        itemBuilder: (context, index) {
                          final s = _mySchools[index];
                          final isSubValid = s['is_subscription_valid'] == true || s['subscription_active'] == true;
                          return SoftCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(s['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSubValid ? Colors.green.shade100 : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isSubValid ? 'Plan Active (MWK 5k/mo)' : 'Subscription Inactive',
                                        style: TextStyle(color: isSubValid ? Colors.green.shade800 : Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('${s['city']} • ${s['curriculum']} | App Fee: MWK ${s['application_fee']}'),
                                if (s['latitude'] != null && s['longitude'] != null)
                                  Text('GPS: ${s['latitude']}, ${s['longitude']}', style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12)),
                                const Divider(height: 24),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange, foregroundColor: Colors.white),
                                      icon: const Icon(Icons.payment, size: 16),
                                      label: Text(isSubValid ? 'Renew Plan (MWK 5,000)' : 'Subscribe (MWK 5,000/mo)'),
                                      onPressed: () => _renewMonthlySubscription(s['id']),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Edit'),
                                          onPressed: () async {
                                            final u = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => SchoolFormScreen(school: s)));
                                            if (u == true) _fetchMySchools();
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                          onPressed: () => _deleteSchool(s['id'], s['name']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

            // Tab 2: Admissions
            _isLoadingApps
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _applications.isEmpty
                    ? Center(child: SoftCard(padding: const EdgeInsets.all(24), child: const Text('No student applications yet.')))
                    : ListView.builder(
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          return SoftCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Applicant ID: ${app['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Desired Grade: ${app['desired_grade']}'),
                                Text('Status: ${app['status']}', style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                if (app['status'] == 'ACCEPTED')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                                        SizedBox(width: 6),
                                        Text('Status: ACCEPTED (Enrolled in Gradebook)', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                else if (app['status'] == 'REJECTED')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                                        SizedBox(width: 6),
                                        Text('Status: REJECTED', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.check, size: 16),
                                        onPressed: () => _updateStatus(app['id'], 'ACCEPTED'),
                                        label: const Text('Accept'),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                        icon: const Icon(Icons.close, size: 16),
                                        onPressed: () => _updateStatus(app['id'], 'REJECTED'),
                                        label: const Text('Reject'),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                          );
                        },
                      ),

            // Tab 3: Enrolled Students & Gradebook (Subscription Gated)
            !subActive
                ? Center(
                    child: SoftCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, size: 64, color: AppColors.accentOrange),
                          const SizedBox(height: 16),
                          const Text('Monthly Subscription Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'To enroll students, post grades, and publish report cards across all levels, subscribe for MWK 5,000 per month.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Subscribe Now (MWK 5,000 / month)', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (_mySchools.isNotEmpty) {
                                _renewMonthlySubscription(_mySchools.first['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : _isLoadingStudents
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                    : Column(
                        children: [
                          SoftCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_enrolledStudents.length} Students in Database', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.person_add, size: 16),
                                  label: const Text('Add Student'),
                                  onPressed: () async {
                                    if (_mySchools.isEmpty) return;
                                    final added = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(builder: (_) => AddStudentScreen(schoolId: _mySchools.first['id'])),
                                    );
                                    if (added == true) _fetchEnrolledStudents();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _enrolledStudents.isEmpty
                                ? Center(child: SoftCard(padding: const EdgeInsets.all(24), child: const Text('No students enrolled yet. Tap "Add Student" to begin.')))
                                : ListView.builder(
                                    itemCount: _enrolledStudents.length,
                                    itemBuilder: (context, i) {
                                      final st = _enrolledStudents[i];
                                      return SoftCard(
                                        padding: const EdgeInsets.all(14),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => StudentGradesScreen(student: st, isSchoolAdmin: true)),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppColors.primaryTeal.withOpacity(0.14),
                                              child: Text('${st['first_name'][0]}', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('${st['first_name']} ${st['last_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                  Text('ID: ${st['student_id_number']} • Class: ${st['current_grade_level']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => StudentGradesScreen(student: st, isSchoolAdmin: true)),
                                                );
                                              },
                                              child: const Text('Grades'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}
