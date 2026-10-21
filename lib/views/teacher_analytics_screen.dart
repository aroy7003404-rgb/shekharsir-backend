import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/teacher_analytics_provider.dart';

class TeacherAnalyticsScreen extends ConsumerWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherAnalyticsProvider);
    final notifier = ref.read(teacherAnalyticsProvider.notifier);

    final analytics = state.analytics ?? {
      'total_students': 148,
      'active_classrooms': 12,
      'completed_sessions': 52,
      'total_teaching_hours': 126.5,
      'average_attendance_rate': 94.2,
      'weekly_attendance_trend': [
        {'day': 'Mon', 'rate': 92.5},
        {'day': 'Tue', 'rate': 95.0},
        {'day': 'Wed', 'rate': 91.8},
        {'day': 'Thu', 'rate': 96.2},
        {'day': 'Fri', 'rate': 94.0},
        {'day': 'Sat', 'rate': 93.5},
      ],
    };

    final List<dynamic> trends = analytics['weekly_attendance_trend'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Teacher Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            onPressed: () {
              notifier.loadAnalytics();
            },
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Metric Summary Grid (4 Primary Indicators)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _buildMetricCard(
                        title: 'Total Enrolled',
                        value: '${analytics['total_students'] ?? 148}',
                        unit: 'Students',
                        icon: Icons.groups_rounded,
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFE0EAFF),
                      ),
                      _buildMetricCard(
                        title: 'Avg Attendance',
                        value: '${analytics['average_attendance_rate'] ?? 94.2}%',
                        unit: 'Participation',
                        icon: Icons.fact_check_rounded,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                      _buildMetricCard(
                        title: 'Teaching Hours',
                        value: '${analytics['total_teaching_hours'] ?? 126.5}',
                        unit: 'Live Hours',
                        icon: Icons.timer_outlined,
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                      _buildMetricCard(
                        title: 'Live Sessions',
                        value: '${analytics['completed_sessions'] ?? 52}',
                        unit: 'Completed',
                        icon: Icons.video_camera_front_rounded,
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFEDE9FE),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Weekly Attendance Trend Visualizer Chart Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weekly Attendance Trend',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Icon(Icons.trending_up_rounded, color: Color(0xFF059669)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Average student check-in rate across Grade 11 & 12 batches.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),

                        // Custom Attendance Bar Chart Visualizer
                        SizedBox(
                          height: 160,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: trends.map((item) {
                              final rate = (item['rate'] as num?)?.toDouble() ?? 90.0;
                              final day = item['day']?.toString() ?? '';
                              final heightFactor = (rate - 70) / 30; // Scale 70-100%

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${rate.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 24,
                                    height: (heightFactor * 100).clamp(20.0, 110.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    day,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Batch Performance Insights Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Batch Performance Highlights',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const Divider(height: 24),
                        _buildInsightRow(
                          batch: 'Grade 12 Physics (Batch A)',
                          status: 'Highest Engagement',
                          rate: '96.4%',
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 12),
                        _buildInsightRow(
                          batch: 'NEET Droppers Physics',
                          status: 'Optimal Assessment Score',
                          rate: '94.8%',
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 12),
                        _buildInsightRow(
                          batch: 'Grade 11 Physics (Batch C)',
                          status: 'Consistent Attendance',
                          rate: '91.2%',
                          color: const Color(0xFFD97706),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required String batch,
    required String status,
    required String rate,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              batch,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rate,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}
