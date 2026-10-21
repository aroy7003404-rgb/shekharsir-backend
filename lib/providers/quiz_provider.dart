import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/quiz_repository.dart';
import 'auth_provider.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return QuizRepository(apiService);
});

class QuizResultState {
  final bool isLoading;
  final Map<String, dynamic>? results;
  final String? errorMessage;

  const QuizResultState({
    this.isLoading = false,
    this.results,
    this.errorMessage,
  });

  QuizResultState copyWith({
    bool? isLoading,
    Map<String, dynamic>? results,
    String? errorMessage,
  }) {
    return QuizResultState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QuizResultNotifier extends StateNotifier<QuizResultState> {
  final QuizRepository _repository;

  QuizResultNotifier(this._repository) : super(const QuizResultState()) {
    loadResults('1');
  }

  Future<void> loadResults(String quizId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchQuizResultsAndLeaderboard(quizId);
      state = state.copyWith(isLoading: false, results: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final quizResultProvider =
    StateNotifierProvider.autoDispose<QuizResultNotifier, QuizResultState>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return QuizResultNotifier(repository);
});
