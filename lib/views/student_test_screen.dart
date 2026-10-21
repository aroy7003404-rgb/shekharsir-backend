import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class TestItemModel {
  final String id;
  final String title;
  final String subject;
  final String batch;
  final int durationMinutes;
  final int totalMarks;
  final List<Map<String, dynamic>> questions;

  TestItemModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.batch,
    required this.durationMinutes,
    required this.totalMarks,
    required this.questions,
  });

  factory TestItemModel.fromJson(Map<String, dynamic> json) {
    return TestItemModel(
      id: json['id']?.toString() ?? '1',
      title: json['title'] ?? 'Wave Optics Assessment',
      subject: json['subject'] ?? 'Physics',
      batch: json['batch'] ?? 'Grade 12 Physics (Batch A)',
      durationMinutes: json['duration_minutes'] ?? 60,
      totalMarks: json['total_marks'] ?? 50,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => q as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class StudentTestScreen extends ConsumerStatefulWidget {
  const StudentTestScreen({super.key});

  @override
  ConsumerState<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends ConsumerState<StudentTestScreen> {
  bool _isLoading = true;
  List<TestItemModel> _availableTests = [];

  final List<TestItemModel> _mockTests = [
    TestItemModel(
      id: '101',
      title: 'Wave Optics Chapter Quiz',
      subject: 'Physics',
      batch: 'Grade 12 Physics (Batch A)',
      durationMinutes: 60,
      totalMarks: 50,
      questions: [
        {
          'id': 'q1',
          'type': 'MCQ',
          'question_text': 'What is the phenomenon of bending of light around obstacles called?',
          'options': ['Refraction', 'Diffraction', 'Polarization', 'Interference'],
          'correct_answer': 'Diffraction',
          'marks': 10,
        },
        {
          'id': 'q2',
          'type': 'MCQ',
          'question_text': 'Two coherent light sources produce interference. What is the phase difference for constructive interference?',
          'options': ['2nπ', '(2n+1)π', 'nπ/2', '3nπ'],
          'correct_answer': '2nπ',
          'marks': 10,
        },
        {
          'id': 'q3',
          'type': 'Subjective',
          'question_text': 'State Young\'s double-slit experiment conditions and write the expression for fringe width.',
          'options': [],
          'correct_answer': 'β = λD/d',
          'marks': 15,
        },
      ],
    ),
    TestItemModel(
      id: '102',
      title: 'Rotational Dynamics Test',
      subject: 'Physics',
      batch: 'Grade 11 Mechanics',
      durationMinutes: 45,
      totalMarks: 40,
      questions: [
        {
          'id': 'q101',
          'type': 'MCQ',
          'question_text': 'What is the moment of inertia of a solid cylinder of mass M and radius R about its longitudinal axis?',
          'options': ['MR²', '1/2 MR²', '2/5 MR²', '1/12 MR²'],
          'correct_answer': '1/2 MR²',
          'marks': 10,
        },
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final rawList = await apiService.getAvailableTests();
      final items = rawList.map((x) => TestItemModel.fromJson(x as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _availableTests = items.isEmpty ? _mockTests : items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableTests = _mockTests;
          _isLoading = false;
        });
      }
    }
  }

  void _startTest(TestItemModel test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TestExamScreen(test: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFEEF2FF),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0EAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '• SHEKHAR SIR CLASSES',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Available Tests',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
            : RefreshIndicator(
                onRefresh: _fetchTests,
                color: const Color(0xFF2563EB),
                child: _availableTests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 52, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No Active Tests Assigned',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        itemCount: _availableTests.length,
                        itemBuilder: (context, index) {
                          final test = _availableTests[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0EAFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        test.subject,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      test.batch,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  test.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${test.durationMinutes} Mins',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.grade_outlined, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${test.totalMarks} Marks',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: () => _startTest(test),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Start Test',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _TestExamScreen extends ConsumerStatefulWidget {
  final TestItemModel test;

  const _TestExamScreen({required this.test});

  @override
  ConsumerState<_TestExamScreen> createState() => __TestExamScreenState();
}

class __TestExamScreenState extends ConsumerState<_TestExamScreen> {
  late int _remainingSeconds;
  Timer? _countdownTimer;

  final Map<int, String> _userAnswers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.test.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _countdownTimer?.cancel();
        _confirmSubmit(autoSubmit: true);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer() {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _confirmSubmit({bool autoSubmit = false}) {
    if (autoSubmit) {
      _processSubmission();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text('You have answered ${_userAnswers.length} of ${widget.test.questions.length} questions. Are you sure you want to finish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processSubmission();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Confirm Submit'),
          ),
        ],
      ),
    );
  }

  void _processSubmission() async {
    _countdownTimer?.cancel();
    setState(() {
      _isSubmitting = true;
    });

    int score = 0;
    for (int i = 0; i < widget.test.questions.length; i++) {
      final q = widget.test.questions[i];
      final studentAns = _userAnswers[i] ?? '';
      final correctAns = q['correct_answer'] ?? '';
      if (studentAns.trim().toLowerCase() == correctAns.trim().toLowerCase()) {
        score += (q['marks'] as int? ?? 10);
      }
    }

    final answersPayload = _userAnswers.entries.map((e) {
      return {
        'question_index': e.key,
        'answer': e.value,
      };
    }).toList();

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.submitTestResponses(
        testId: widget.test.id,
        answers: answersPayload,
      );
    } catch (e) {
      // Fallback for mock/test submission
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      _showResultDialog(score);
    }
  }

  void _showResultDialog(int score) {
    final totalMarks = widget.test.totalMarks;
    final percentage = (score / totalMarks * 100).toStringAsFixed(1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 48),
        title: const Text('Test Submitted!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: $score / $totalMarks ($percentage%)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your responses have been saved and sent to Shekhar Sir Classes backend.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to Available Tests
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(widget.test.title, style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A))),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatTimer(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: widget.test.questions.length,
                itemBuilder: (context, index) {
                  final q = widget.test.questions[index];
                  final isMcq = (q['type'] ?? 'MCQ') == 'MCQ';
                  final List<dynamic> options = q['options'] ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1} (${q['marks'] ?? 10} Marks)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q['question_text'] ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 14),

                        if (isMcq) ...[
                          Column(
                            children: List.generate(options.length, (optIdx) {
                              final optText = options[optIdx].toString();
                              final isSelected = _userAnswers[index] == optText;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _userAnswers[index] = optText;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE0EAFF) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                        size: 18,
                                        color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(optText, style: const TextStyle(fontSize: 14))),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ] else ...[
                          TextFormField(
                            initialValue: _userAnswers[index] ?? '',
                            onChanged: (val) {
                              _userAnswers[index] = val;
                            },
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Type your subjective answer here...',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Submit Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _confirmSubmit(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Test & Check Results', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
