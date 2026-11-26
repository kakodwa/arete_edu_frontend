import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';
import '../payments/payment_screen.dart';
import '../exams/exam_screen.dart';
import 'school_detail_screen.dart';

class SchoolListScreen extends StatefulWidget {
  const SchoolListScreen({super.key});

  @override
  State<SchoolListScreen> createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends State<SchoolListScreen> {
  List<dynamic> _schools = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  void _fetchSchools() async {
    try {
      final res = await ApiService.get('schools/?search=$_searchQuery');
      if (res.statusCode == 200) {
        setState(() {
          _schools = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSchoolCard(Map<String, dynamic> s) {
    final hasGps = s['latitude'] != null && s['longitude'] != null;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SchoolDetailScreen(school: s)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: AppColors.primaryTeal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkSlate),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text('${s['city']} • ${s['curriculum']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s['overview'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
          ),
          const Spacer(),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'App Fee: MWK ${s['application_fee']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentOrange, fontSize: 13),
              ),
              Row(
                children: [
                  if (hasGps)
                    const Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: Icon(Icons.gps_fixed, size: 15, color: AppColors.primaryTeal),
                    ),
                  const Text('Details', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryTeal),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return ResponsiveContainer(
      maxWidth: 1250,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            margin: const EdgeInsets.only(bottom: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by school name, city (Lilongwe, Blantyre...), or curriculum...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryTeal),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                _searchQuery = val;
                _fetchSchools();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _schools.isEmpty
                    ? const Center(child: Text('No verified private schools found.'))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 195,
                        ),
                        itemCount: _schools.length,
                        itemBuilder: (context, idx) => _buildSchoolCard(_schools[idx]),
                      ),
          ),
        ],
      ),
    );
  }
}

class ClientApplicationsScreen extends StatefulWidget {
  const ClientApplicationsScreen({super.key});

  @override
  State<ClientApplicationsScreen> createState() => _ClientApplicationsScreenState();
}

class _ClientApplicationsScreenState extends State<ClientApplicationsScreen> {
  List<dynamic> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('admissions/');
      if (res.statusCode == 200) {
        setState(() {
          _apps = jsonDecode(res.body);
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING_FEE':
        return Colors.orange;
      case 'EXAM_READY':
        return AppColors.primaryTeal;
      case 'EXAM_COMPLETED':
        return Colors.blue;
      case 'ACCEPTED':
        return AppColors.successGreen;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_FEE':
        return 'Payment Required';
      case 'EXAM_READY':
        return 'Fee Verified: Exam Unlocked';
      case 'EXAM_COMPLETED':
        return 'Exam Submitted: Under Review';
      case 'ACCEPTED':
        return 'Admitted / Accepted';
      case 'REJECTED':
        return 'Application Declined';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 850,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _apps.isEmpty
              ? Center(
                  child: SoftCard(
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('You have not applied to any schools yet.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _fetch(),
                  child: ListView.builder(
                    itemCount: _apps.length,
                    itemBuilder: (context, i) {
                      final a = _apps[i];
                      final status = a['status'];
                      final schoolName = a['school_detail']?['name'] ?? 'School Application';
                      final fee = a['school_detail']?['application_fee'] ?? '15000.00';

                      return SoftCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    schoolName,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getStatusLabel(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Grade / Form: ${a['desired_grade']}'),
                            Text('Application ID: ${a['id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Divider(height: 24),

                            if (status == 'PENDING_FEE') ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Application fee (MWK $fee) is required to unlock your entrance exam.',
                                        style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Pay Registration Fee (Airtel / Mpamba / PRN)'),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PaymentScreen(applicationId: a['id'])),
                                    );
                                    _fetch();
                                  },
                                ),
                              ),
                            ] else if (status == 'EXAM_READY') ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Payment confirmed! Your digital entrance exam is ready. Sit in a quiet environment.',
                                        style: TextStyle(fontSize: 12, color: AppColors.darkSlate, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text('Sit Entrance Exam Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ExamTakingScreen(applicationId: a['id'])),
                                    );
                                    _fetch();
                                  },
                                ),
                              ),
                            ] else if (status == 'EXAM_COMPLETED') ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.hourglass_top, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your exam answers have been saved and submitted to school administrators for admission review.',
                                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (status == 'ACCEPTED') ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, color: AppColors.successGreen, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Congratulations! You have been accepted. Contact the school administration for term start information.',
                                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
