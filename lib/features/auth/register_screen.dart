import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  String _selectedRole = 'CLIENT'; // 'CLIENT' or 'SCHOOL'
  bool _isUnder18 = false;
  bool _parentConsentGiven = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUnder18 && !_parentConsentGiven) {
      setState(() {
        _errorMessage = 'Parental consent must be explicitly granted for applicants under 18.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': _selectedRole,
      'is_under_18': _isUnder18,
      'parent_consent_given': _isUnder18 ? _parentConsentGiven : false,
      'guardian_name': _isUnder18 ? _guardianNameController.text.trim() : null,
      'guardian_phone': _isUnder18 ? _guardianPhoneController.text.trim() : null,
    };

    try {
      final response = await ApiService.post('auth/register/', payload);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully! Please log in.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          _errorMessage = err.values.first is List ? err.values.first[0] : 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network connection failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create aretéEDU Account'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 580,
              child: SoftCard(
                padding: const EdgeInsets.all(24),
                child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join aretéEDU',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select your account role and complete your profile.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Role Selector
                const Text('Account Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Parent / Student')),
                        selected: _selectedRole == 'CLIENT',
                        selectedColor: AppColors.primaryTeal,
                        labelStyle: TextStyle(
                          color: _selectedRole == 'CLIENT' ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedRole = 'CLIENT');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('School Admin')),
                        selected: _selectedRole == 'SCHOOL',
                        selectedColor: AppColors.primaryTeal,
                        labelStyle: TextStyle(
                          color: _selectedRole == 'SCHOOL' ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedRole = 'SCHOOL';
                              _isUnder18 = false;
                              _parentConsentGiven = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a username' : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (e.g. 099xxxxxxx / 088xxxxxxx)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => v == null || v.trim().length < 9 ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) => v != null && v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),

                // Minor & Parental Consent Fields (For CLIENT role)
                if (_selectedRole == 'CLIENT') ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Is the applicant under 18 years old?'),
                    value: _isUnder18,
                    activeColor: AppColors.primaryTeal,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isUnder18 = val),
                  ),
                  if (_isUnder18) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _guardianNameController,
                      decoration: const InputDecoration(
                        labelText: 'Parent / Guardian Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      validator: (v) => _isUnder18 && (v == null || v.trim().isEmpty) ? 'Required for applicants under 18' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _guardianPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Parent / Guardian Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      validator: (v) => _isUnder18 && (v == null || v.trim().isEmpty) ? 'Guardian contact required' : null,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text(
                        'I confirm that I have obtained parental / guardian consent for this account and data processing.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _parentConsentGiven,
                      activeColor: AppColors.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _parentConsentGiven = val ?? false),
                    ),
                  ],
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
