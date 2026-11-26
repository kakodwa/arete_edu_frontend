import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../schools/school_list_screen.dart';
import '../schools/results_portal_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'school_admin_dashboard.dart';
import 'platform_admin_dashboard.dart';

class DashboardDispatcher extends StatelessWidget {
  final String role;
  const DashboardDispatcher({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == 'ADMIN') {
      return const PlatformAdminDashboard();
    } else if (role == 'SCHOOL') {
      return const SchoolAdminDashboard();
    } else {
      return ClientHomeScreen(isGuest: role == 'GUEST');
    }
  }
}

class ClientHomeScreen extends StatefulWidget {
  final bool isGuest;
  const ClientHomeScreen({super.key, this.isGuest = false});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;
  String _username = 'Guest Explorer';
  bool _isLoggedIn = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Discover Malawian Schools',
    'My Admissions & Examinations',
    'Student Academic Results',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    setState(() {
      _isLoggedIn = token != null;
      _username = prefs.getString('username') ?? 'Guest Explorer';
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardDispatcher(role: 'GUEST')));
  }

  Widget _buildGuestAuthPrompt(String featureName) {
    return ResponsiveContainer(
      maxWidth: 500,
      child: SoftCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, size: 54, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 18),
            Text(
              'Sign In to Access $featureName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
            ),
            const SizedBox(height: 10),
            const Text(
              'Browsing private schools and checking campus locations is open to all guests. Please log in or create an account to apply, pay fees, sit entrance exams, or view report cards.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.45),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Text('Log In to Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentOrange,
                  side: const BorderSide(color: AppColors.accentOrange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('Create Free Parent / Student Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCurrentBody() {
    if (_currentIndex == 0) {
      return const SchoolListScreen();
    } else if (_currentIndex == 1) {
      return _isLoggedIn ? const ClientApplicationsScreen() : _buildGuestAuthPrompt('Admissions & Exams');
    } else {
      return const ClientResultsPortalScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = !Responsive.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkSlate,
        leading: isWideScreen
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.primaryTeal),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('aretéEDU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _titles[_currentIndex],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkSlate),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.grey),
              tooltip: 'Sign Out',
              onPressed: _logout,
            ),
        ],
      ),

      drawer: isWideScreen
          ? null
          : Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.darkSlate, AppColors.primaryTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'G',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                    ),
                    accountName: Text(_username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    accountEmail: Text(_isLoggedIn ? 'Verified Account' : 'Guest Browsing Mode', style: const TextStyle(fontSize: 12)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.school, color: AppColors.primaryTeal),
                    title: const Text('Find Private Schools'),
                    selected: _currentIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: AppColors.primaryTeal),
                    title: const Text('My Applications & Exams'),
                    selected: _currentIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.grade, color: AppColors.primaryTeal),
                    title: const Text('Academic Results & Report Cards'),
                    selected: _currentIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  const Spacer(),
                  if (!_isLoggedIn)
                    ListTile(
                      leading: const Icon(Icons.login, color: AppColors.primaryTeal),
                      title: const Text('Log In / Sign Up', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                      title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      onTap: _logout,
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

      // Adaptive Body: Side NavigationRail on Tablet/Desktop, standard body on Mobile
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              extended: Responsive.isDesktop(context),
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: AppColors.primaryTeal),
              selectedLabelTextStyle: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.school_rounded), label: Text('Explore Schools')),
                NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: Text('Admissions & Exams')),
                NavigationRailDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade_rounded), label: Text('My Results')),
              ],
            ),
          if (isWideScreen) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getCurrentBody()),
        ],
      ),

      // BottomNavigationBar on Mobile only
      bottomNavigationBar: isWideScreen
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                elevation: 0,
                backgroundColor: Colors.white,
                selectedItemColor: AppColors.primaryTeal,
                unselectedItemColor: Colors.grey.shade400,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.search_rounded), activeIcon: Icon(Icons.school_rounded), label: 'Explore'),
                  BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Admissions'),
                  BottomNavigationBarItem(icon: Icon(Icons.grade_outlined), activeIcon: Icon(Icons.grade_rounded), label: 'My Results'),
                ],
              ),
            ),
    );
  }
}
