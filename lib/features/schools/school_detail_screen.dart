import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';
import '../auth/login_screen.dart';
import 'school_map_screen.dart';

class SchoolDetailScreen extends StatelessWidget {
  final Map<String, dynamic> school;

  const SchoolDetailScreen({super.key, required this.school});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  void _promptLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Account Required'),
        content: const Text(
          'You are currently browsing as a Guest. Please log in or sign up to apply, sit entrance exams, or pay school fees.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue Browsing')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context) async {
    final loggedIn = await _isLoggedIn();
    if (!context.mounted) return;
    if (!loggedIn) {
      _promptLogin(context);
      return;
    }

    final gradeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Apply to ${school['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Application Fee:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'MWK ${school['application_fee']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentOrange, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: gradeCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Grade / Form',
                hintText: 'e.g., Form 1, Standard 7, Year 10',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final grade = gradeCtrl.text.trim();
              if (grade.isEmpty) return;
              Navigator.pop(ctx);
              final res = await ApiService.post('admissions/', {
                'school': school['id'],
                'desired_grade': grade,
              });
              if (res.statusCode == 201) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Application submitted! View it in Admissions to complete payment.'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );
  }

  void _openMapScreen(BuildContext context) {
    final lat = double.tryParse(school['latitude']?.toString() ?? '') ?? -13.9626;
    final lng = double.tryParse(school['longitude']?.toString() ?? '') ?? 33.7741;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchoolMapScreen(
          schoolName: school['name'] ?? 'Campus Map',
          city: school['city'] ?? 'Malawi',
          address: school['address'] ?? '',
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tuitionMin = school['annual_tuition_min'] ?? 0;
    final tuitionMax = school['annual_tuition_max'] ?? 0;
    final overview = school['overview'] ?? 'No description provided.';
    final performance = school['exam_performance_summary'] ?? 'Track record details available upon request.';
    final address = school['address'] ?? 'Not specified';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210.0,
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                school['name'] ?? 'School Details',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkSlate, AppColors.primaryTeal],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.school, size: 75, color: Colors.white.withOpacity(0.28)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveContainer(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges & Map Action Row
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          school['curriculum'] ?? 'MANEB',
                          style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 15, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(school['city'] ?? 'Malawi', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryTeal,
                          side: const BorderSide(color: AppColors.primaryTeal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('View Campus on Map', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _openMapScreen(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fee SoftCard
                  SoftCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Annual Tuition:', style: TextStyle(color: Colors.grey)),
                            Text(
                              'MWK $tuitionMin - $tuitionMax',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Entrance Application Fee:', style: TextStyle(color: Colors.grey)),
                            Text(
                              'MWK ${school['application_fee']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentOrange,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Overview SoftCard
                  SoftCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overview & Campus Facilities', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(overview, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                      ],
                    ),
                  ),

                  // Exam Performance SoftCard
                  SoftCard(
                    padding: const EdgeInsets.all(18),
                    color: Colors.amber.shade50.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.emoji_events_outlined, color: AppColors.accentOrange),
                            SizedBox(width: 8),
                            Text('Academic Track Record & Highlights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          performance,
                          style: TextStyle(fontSize: 14, height: 1.45, color: Colors.brown.shade800),
                        ),
                      ],
                    ),
                  ),

                  // Location SoftCard with Map Launch Action
                  SoftCard(
                    padding: const EdgeInsets.all(18),
                    onTap: () => _openMapScreen(context),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.pin_drop, color: AppColors.primaryTeal, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Campus Location & GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(address, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              if (school['latitude'] != null && school['longitude'] != null)
                                Text(
                                  'Coordinates: ${school['latitude']}, ${school['longitude']}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new, color: AppColors.primaryTeal),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Primary Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Apply to this School', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () => _showApplyDialog(context),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
