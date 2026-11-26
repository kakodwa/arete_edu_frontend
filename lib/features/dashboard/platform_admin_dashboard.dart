import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../dashboard/dashboard_dispatcher.dart';

class PlatformAdminDashboard extends StatelessWidget {
  const PlatformAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('aretéEDU Superadmin Panel'),
        backgroundColor: AppColors.darkSlate,
        foregroundColor: Colors.white,
        actions: [
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
        maxWidth: 900,
        child: Column(
          children: [
            SoftCard(
              padding: const EdgeInsets.all(18),
              onTap: () {},
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryTeal,
                    child: Icon(Icons.account_balance, color: Colors.white),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('School Verification Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Review and approve newly registered private school profiles across Malawi', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            SoftCard(
              padding: const EdgeInsets.all(18),
              onTap: () {},
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accentOrange,
                    child: Icon(Icons.payment, color: Colors.white),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Global Fee Reconciliation & Subscriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Audit Airtel Money, TNM Mpamba, Bank PRNs & MWK 5,000/mo School Plans', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
