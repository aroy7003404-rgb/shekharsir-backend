import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/teacher_analytics_repository.dart';
import 'auth_provider.dart';

final teacherAnalyticsRepositoryProvider = Provider<TeacherAnalyticsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TeacherAnalyticsRepository(apiService);
});

class AnalyticsState {
  final bool isLoading;
  final Map<String, dynamic>? analytics;
  final String? errorMessage;

  const AnalyticsState({
    this.isLoading = false,
    this.analytics,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? analytics,
    String? errorMessage,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      analytics: analytics ?? this.analytics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final TeacherAnalyticsRepository _repository;

  AnalyticsNotifier(this._repository) : super(const AnalyticsState()) {
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchAnalyticsSummary();
      state = state.copyWith(isLoading: false, analytics: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final teacherAnalyticsProvider =
    StateNotifierProvider.autoDispose<AnalyticsNotifier, AnalyticsState>((ref) {
  final repository = ref.watch(teacherAnalyticsRepositoryProvider);
  return AnalyticsNotifier(repository);
});
