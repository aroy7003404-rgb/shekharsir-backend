import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';

class QuizLeaderboardScreen extends ConsumerWidget {
  const QuizLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizResultProvider);
    final results = state.results ?? {
      'score': '88 / 100',
      'grade': 'Grade A+ • Excellent',
      'percentile': 'Top 4%',
      'accuracy': '88%',
      'time_spent': '18m 42s',
      'rank': '#2',
      'participant_count': '48 Students',
      'podium': [
        {'rank': 1, 'name': 'Devansh Verma', 'score': '96 pts', 'badge': 'Gold #1', 'avatar_letter': 'D', 'is_you': false},
        {'rank': 2, 'name': 'Aarav Sharma (You)', 'score': '88 pts', 'badge': 'Silver #2', 'avatar_letter': 'A', 'is_you': true},
        {'rank': 3, 'name': 'Ananya Gupta', 'score': '84 pts', 'badge': 'Bronze #3', 'avatar_letter': 'A', 'is_you': false},
      ],
      'leaderboard_list': [
        {'rank': 4, 'name': 'Ishita Patel', 'accuracy': '82%', 'score': '82 pts', 'avatar_letter': 'I'},
        {'rank': 5, 'name': 'Rohan Mehta', 'accuracy': '78%', 'score': '78 pts', 'avatar_letter': 'R'},
        {'rank': 6, 'name': 'Priya Singh', 'accuracy': '75%', 'score': '75 pts', 'avatar_letter': 'P'},
        {'rank': 7, 'name': 'Karan Malhotra', 'accuracy': '70%', 'score': '70 pts', 'avatar_letter': 'K'},
        {'rank': 8, 'name': 'Siddharth Rao', 'accuracy': '68%', 'score': '68 pts', 'avatar_letter': 'S'},
      ]
    };

    final List<dynamic> podium = results['podium'] as List<dynamic>? ?? [];
    final List<dynamic> leaderboardList = results['leaderboard_list'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0EAFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'SHEKHAR SIR CLASSES',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Assessment Results & Leaderboard',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. Overall Test Results Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                results['grade'] ?? 'Grade A+',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                results['percentile'] ?? 'Top 4%',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Overall Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          results['score'] ?? '88 / 100',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),

                        // Stats Summary Bar (Accuracy, Time Spent, Rank)
                        Row(
                          children: [
                            _buildStatItem('Accuracy', results['accuracy'] ?? '88%', Icons.check_circle_outline),
                            _buildStatItem('Time Spent', results['time_spent'] ?? '18m 42s', Icons.timer_outlined),
                            _buildStatItem('Class Rank', results['rank'] ?? '#2', Icons.emoji_events_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Class Leaderboard Header & Participant Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Class Leaderboard',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0EAFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          results['participant_count'] ?? '48 Students',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Top 3 Podium View (#1 Center Gold, #2 Left Silver "You", #3 Right Bronze)
                  if (podium.length >= 3)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // #2 Silver (Left - "You")
                          _buildPodiumColumn(
                            item: podium[1],
                            rankColor: const Color(0xFF94A3B8),
                            height: 100,
                          ),
                          // #1 Gold (Center - Highest)
                          _buildPodiumColumn(
                            item: podium[0],
                            rankColor: const Color(0xFFD97706),
                            height: 130,
                            isGold: true,
                          ),
                          // #3 Bronze (Right)
                          _buildPodiumColumn(
                            item: podium[2],
                            rankColor: const Color(0xFFB45309),
                            height: 85,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 4. Leaderboard List (#4 Onwards)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leaderboardList.length,
                    itemBuilder: (context, index) {
                      final item = leaderboardList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#${item['rank']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFE0EAFF),
                              child: Text(
                                item['avatar_letter'] ?? 'S',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Student',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'Accuracy: ${item['accuracy'] ?? '80%'}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item['score'] ?? '80 pts',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 5. Primary Action Button: "Review Solutions" (Share button explicitly excluded)
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Review Solutions & Explanations'),
                          content: const Text(
                            'Displaying detailed answer keys, step-by-step derivations, and instructor solution notes for all 10 questions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white),
                    label: const Text('Review Solutions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required dynamic item,
    required Color rankColor,
    required double height,
    bool isGold = false,
  }) {
    final bool isYou = item['is_you'] == true;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isYou)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        CircleAvatar(
          radius: isGold ? 22 : 18,
          backgroundColor: rankColor.withOpacity(0.2),
          child: Text(
            item['avatar_letter'] ?? 'S',
            style: TextStyle(fontWeight: FontWeight.bold, color: rankColor, fontSize: isGold ? 16 : 13),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item['name'] ?? '',
          style: TextStyle(fontSize: 11, fontWeight: isYou ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF0F172A)),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item['score'] ?? '',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rankColor),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: rankColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              '#${item['rank']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: rankColor),
            ),
          ),
        ),
      ],
    );
  }
}
