import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';
import '../exams/exam_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String applicationId;
  const PaymentScreen({super.key, required this.applicationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'AIRTEL_MONEY';
  final _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isCheckingStatus = false;
  Map<String, dynamic>? _transactionData;
  String? _paymentStatus; // 'PENDING', 'SUCCESSFUL', 'FAILED'
  String? _applicationStatus; // 'PENDING_FEE', 'EXAM_READY'

  void _initiatePayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number to authorize payment.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final res = await ApiService.post('payments/initiate/', {
        'application_id': widget.applicationId,
        'method': _selectedMethod,
        'phone_number': phone,
      });

      setState(() => _isProcessing = false);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _transactionData = data;
          _paymentStatus = data['status'] ?? 'PENDING';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate payment: ${res.body}')),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Check your server connection.')),
      );
    }
  }

  void _checkStatus() async {
    if (_transactionData == null || _transactionData!['prn'] == null) return;
    final prn = _transactionData!['prn'];

    setState(() => _isCheckingStatus = true);
    try {
      final res = await ApiService.get('payments/status/$prn/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _paymentStatus = data['status'];
          _applicationStatus = data['application_status'];
        });

        if (!mounted) return;
        if (_applicationStatus == 'EXAM_READY' || _paymentStatus == 'SUCCESSFUL') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment confirmed! Entrance exam unlocked.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment still pending confirmation. Please wait or check your USSD prompt.')),
          );
        }
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Fee Checkout'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _transactionData != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    _applicationStatus == 'EXAM_READY' ? Icons.check_circle : Icons.pending_actions,
                    color: _applicationStatus == 'EXAM_READY' ? AppColors.successGreen : AppColors.accentOrange,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _applicationStatus == 'EXAM_READY' ? 'Payment Verified!' : 'Payment Prompt Sent',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('Payment Reference Number (PRN):', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        SelectableText(
                          _transactionData!['prn'] ?? '',
                          style: const TextStyle(fontSize: 20, color: AppColors.accentOrange, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Total Amount: MWK ${_transactionData!['total_payable']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_applicationStatus == 'EXAM_READY') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Your entrance examination is now active! You can sit the exam right now or take it later from your dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_note, size: 24),
                      label: const Text('Start Entrance Exam Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamTakingScreen(applicationId: widget.applicationId),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Text(
                      '1. If using Airtel Money or TNM Mpamba, enter your PIN when prompted on your mobile phone.\n'
                      '2. If paying via National Bank or Standard Bank deposit, provide the PRN shown above to the teller.\n'
                      '3. Once paid, click the button below to verify.',
                      style: TextStyle(height: 1.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isCheckingStatus
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.sync),
                      label: const Text('Check Payment & Unlock Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isCheckingStatus ? null : _checkStatus,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Return to Applications'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Select Malawian Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SoftCard(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Airtel Money (Instant USSD Push)'),
                          subtitle: const Text('Enter PIN on your Airtel phone prompt'),
                          value: 'AIRTEL_MONEY',
                          activeColor: AppColors.primaryTeal,
                          groupValue: _selectedMethod,
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('TNM Mpamba (Instant USSD Push)'),
                          subtitle: const Text('Enter PIN on your TNM phone prompt'),
                          value: 'TNM_MPAMBA',
                          activeColor: AppColors.primaryTeal,
                          groupValue: _selectedMethod,
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('Bank Deposit via PRN'),
                          subtitle: const Text('National Bank / Standard Bank / First Capital'),
                          value: 'BANK_PRN',
                          activeColor: AppColors.primaryTeal,
                          groupValue: _selectedMethod,
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Payer Phone Number (e.g. 099xxxxxxx / 088xxxxxxx)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isProcessing ? null : _initiatePayment,
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Authorize & Send USSD Prompt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }
}
