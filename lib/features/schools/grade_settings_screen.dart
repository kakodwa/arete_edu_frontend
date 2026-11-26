import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';

class GradeSettingsScreen extends StatefulWidget {
  final int schoolId;
  const GradeSettingsScreen({super.key, required this.schoolId});

  @override
  State<GradeSettingsScreen> createState() => _GradeSettingsScreenState();
}

class _GradeSettingsScreenState extends State<GradeSettingsScreen> {
  List<dynamic> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  void _fetchRules() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('schools/scale-rules/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _rules = data.where((r) => r['school'] == widget.schoolId).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddRuleDialog() {
    final minCtrl = TextEditingController(text: '80');
    final maxCtrl = TextEditingController(text: '100');
    final labelCtrl = TextEditingController(text: 'A*');
    final remarksCtrl = TextEditingController(text: 'Distinction / Excellent');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Grading Condition'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Score %', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Score %', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Grade Symbol / Score (e.g. 1, 2, A*, A, B)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarks (e.g. Distinction, Strong Pass)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.post('schools/scale-rules/', {
                'school': widget.schoolId,
                'min_score': double.tryParse(minCtrl.text.trim()) ?? 0,
                'max_score': double.tryParse(maxCtrl.text.trim()) ?? 100,
                'grade_label': labelCtrl.text.trim(),
                'remarks': remarksCtrl.text.trim(),
              });
              _fetchRules();
            },
            child: const Text('Save Condition'),
          ),
        ],
      ),
    );
  }

  void _deleteRule(int id) async {
    await ApiService.delete('schools/scale-rules/$id/');
    _fetchRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grading Scale Conditions'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune, color: AppColors.primaryTeal),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Customize grade thresholds (e.g. 80-100% = Distinction / A*). When subject marks are posted, student report cards are auto-graded with these rules.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Configured Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Rule'),
                        onPressed: _showAddRuleDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _rules.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rule, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text('No custom grade conditions defined yet.', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                const Text('The system will default to standard MANEB / Cambridge grading until you add rules.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _rules.length,
                            itemBuilder: (context, i) {
                              final r = _rules[i];
                              return SoftCard(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    child: Text('${r['grade_label']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text('Range: ${r['min_score']}% to ${r['max_score']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(r['remarks'] ?? 'No remarks'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _deleteRule(r['id']),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
