import '../services/api_service.dart';

class QuizRepository {
  QuizRepository(ApiService apiService);

  Future<Map<String, dynamic>> fetchQuizResultsAndLeaderboard(String quizId) async {
    try {
      return {
        'score': '88 / 100',
        'raw_score': 88.0,
        'total_marks': 100,
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
    } catch (e) {
      throw Exception('Failed to load quiz results & leaderboard.');
    }
  }
}
