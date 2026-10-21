import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'student_home_screen.dart';
import 'teacher_home_screen.dart';

/// RoleRouter inspects the current user session and dynamically routes
/// to TeacherHomeScreen, StudentHomeScreen, or LoginScreen.
class RoleRouter extends ConsumerStatefulWidget {
  const RoleRouter({super.key});

  @override
  ConsumerState<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends ConsumerState<RoleRouter> {
  @override
  void initState() {
    super.initState();
    // Check local token persistence on initial app startup
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.watch(authControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    // 5. Smooth loading indicator while verifying session token
    if (authController.status == AuthStatus.loading ||
        authController.status == AuthStatus.initial ||
        authState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FE),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
        ),
      );
    }

    // 1. Fetch authenticated user session
    if (authController.status == AuthStatus.authenticated) {
      final user = authController.currentUser;
      final role = (user?['role'] as String?)?.toLowerCase() ?? 'student';

      // 2. Teacher role routing
      if (role == 'teacher') {
        return const TeacherHomeScreen();
      }
      // 3. Student role routing
      else {
        return const StudentHomeScreen();
      }
    }

    // 4. Fallback to LoginScreen if session is invalid or missing
    return const LoginScreen();
  }
}
