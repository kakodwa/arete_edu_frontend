import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';

class ExamTakingScreen extends StatefulWidget {
  final String applicationId;
  const ExamTakingScreen({super.key, required this.applicationId});

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> with WidgetsBindingObserver {
  List<dynamic> _questions = [];
  final Map<int, String> _userAnswers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  int _tamperCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExam();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _tamperCount++;
      // Anti-tamper violation tracked
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadExam() async {
    final res = await ApiService.get('exams/take/${widget.applicationId}/');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _questions = data['questions'] ?? [];
        _isLoading = false;
      });
    }
  }

  void _recordAndSyncAnswer(int questionId, String option) {
    setState(() {
      _userAnswers[questionId] = option;
    });
    // Progressive local saving and background network ping
    ApiService.post('exams/take/${widget.applicationId}/', {
      'answers': [{'question_id': questionId, 'selected_option': option}],
      'tamper_count': _tamperCount,
      'finalize': false,
    });
  }

  void _submitFinalExam() async {
    final answersList = _userAnswers.entries.map((e) => {'question_id': e.key, 'selected_option': e.value}).toList();
    final res = await ApiService.post('exams/take/${widget.applicationId}/', {
      'answers': answersList,
      'tamper_count': _tamperCount,
      'finalize': true,
    });

    if (res.statusCode == 200) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Exam Completed!'),
          content: const Text('Your entrance exam has been submitted securely and auto-graded for the school administration.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Return to Dashboard'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entrance Examination')),
        body: const Center(child: Text('No active questions assigned for this examination yet.')),
      );
    }

    final currentQ = _questions[_currentIndex];
    final qId = currentQ['id'] as int;

    return PopScope(
      canPop: false, // Prevents accidental exit
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Subject: ${currentQ['subject']} (${currentQ['points']} pt)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentOrange),
              ),
              const SizedBox(height: 12),
              Text(currentQ['text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ...['A', 'B', 'C', 'D'].map((opt) {
                final optKey = 'option_${opt.toLowerCase()}';
                final optText = currentQ[optKey];
                if (optText == null || optText.toString().isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _userAnswers[qId] == opt ? AppColors.primaryTeal : Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RadioListTile<String>(
                    title: Text('$opt. $optText'),
                    value: opt,
                    groupValue: _userAnswers[qId],
                    onChanged: (val) => _recordAndSyncAnswer(qId, val!),
                  ),
                );
              }),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton(onPressed: () => setState(() => _currentIndex--), child: const Text('Previous'))
                  else
                    const SizedBox.shrink(),
                  if (_currentIndex < _questions.length - 1)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                      onPressed: () => setState(() => _currentIndex++),
                      child: const Text('Next Question'),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange, foregroundColor: Colors.white),
                      onPressed: _submitFinalExam,
                      child: const Text('Final Submit'),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
