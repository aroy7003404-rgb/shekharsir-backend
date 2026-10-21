import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// 1. Global Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Auth State helper holding authentication status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 2. AuthController class extending StateNotifier
class AuthController extends StateNotifier<AsyncValue<void>> {
  final ApiService _apiService;
  static const String tokenKey = 'jwt_access_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String nameKey = 'user_name';
  static const String emailKey = 'user_email';
  static const String roleKey = 'user_role';
  static const String keepLoggedInKey = 'keep_me_logged_in';
  static const String userKey = 'shekhar_sir_user_json';

  Map<String, dynamic>? _currentUserMap;
  AuthStatus _status = AuthStatus.initial;

  AuthController(this._apiService) : super(const AsyncData(null));

  Map<String, dynamic>? get user => _currentUserMap;
  Map<String, dynamic>? get currentUser => _currentUserMap;
  AuthStatus get status => _status;

  UserModel? get userModel =>
      _currentUserMap != null ? UserModel.fromJson(_currentUserMap!) : null;

  /// Check local token persistence and "Keep me logged in" flag on app startup
  Future<bool> checkAuthStatus() async {
    state = const AsyncLoading();
    _status = AuthStatus.loading;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      final keepLoggedIn = prefs.getBool(keepLoggedInKey) ?? true;
      final savedUserJson = prefs.getString(userKey);

      if (token != null && token.isNotEmpty && keepLoggedIn) {
        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          try {
            _currentUserMap = json.decode(savedUserJson) as Map<String, dynamic>;
          } catch (_) {}
        } else {
          final name = prefs.getString(nameKey) ?? 'User';
          final email = prefs.getString(emailKey) ?? 'user@shekharsir.edu';
          final role = prefs.getString(roleKey) ?? 'student';
          _currentUserMap = {
            'id': 1,
            'name': name,
            'email': email,
            'role': role,
            'is_email_verified': true,
          };
        }
        _status = AuthStatus.authenticated;
        state = const AsyncData(null);
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        state = const AsyncData(null);
        return false;
      }
    } catch (e, stackTrace) {
      _status = AuthStatus.error;
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  void _saveUserData(AuthResponseModel authResponse, bool keepLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, authResponse.accessToken);
    if (authResponse.refreshToken != null) {
      await prefs.setString(refreshTokenKey, authResponse.refreshToken!);
    }
    await prefs.setString(nameKey, authResponse.user.name);
    await prefs.setString(emailKey, authResponse.user.email);
    await prefs.setString(roleKey, authResponse.user.role);
    await prefs.setBool(keepLoggedInKey, keepLoggedIn);
    await prefs.setString(userKey, json.encode(authResponse.user.toJson()));
  }

  /// Sign Up Method
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();
    _status = AuthStatus.loading;
    try {
      final responseMap = await _apiService.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      final authResponse = AuthResponseModel.fromJson(responseMap);

      final userJson = authResponse.user.toJson();
      userJson['role'] = role;

      _currentUserMap = userJson;
      _status = AuthStatus.initial;
      state = const AsyncData(null);

      final updatedResponse = AuthResponseModel(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        tokenType: authResponse.tokenType,
        user: UserModel.fromJson(userJson),
      );

      _saveUserData(updatedResponse, true);

      // Trigger verification code send
      await _apiService.sendVerificationEmail(email: email);
      return true;
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      state = AsyncError(message, stackTrace);
      return false;
    }
  }

  /// Send or Resend Verification Email OTP
  Future<bool> sendVerificationEmail(String email) async {
    try {
      await _apiService.sendVerificationEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify Email OTP Code
  Future<bool> verifyEmailOTP({
    required String email,
    required String code,
    String role = 'student',
    bool keepLoggedIn = true,
  }) async {
    state = const AsyncLoading();
    _status = AuthStatus.loading;
    try {
      final currentRole = _currentUserMap?['role']?.toString().toLowerCase() ?? role.toLowerCase();
      final responseMap = await _apiService.verifyEmail(email: email, code: code, role: currentRole);
      final authResponse = AuthResponseModel.fromJson(responseMap);

      final userJson = authResponse.user.toJson();
      userJson['role'] = currentRole;

      _currentUserMap = userJson;
      final updatedResponse = AuthResponseModel(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        tokenType: authResponse.tokenType,
        user: UserModel.fromJson(userJson),
      );
      _saveUserData(updatedResponse, keepLoggedIn);

      _status = AuthStatus.authenticated;
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      state = AsyncError(message, stackTrace);
      return false;
    }
  }

  /// Alias method for signup
  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    return signUp(
      name: fullName,
      email: email,
      password: password,
      role: 'student',
    );
  }

  /// Login Method with "Keep me logged in" support and Role tracking
  Future<bool> login({
    required String email,
    required String password,
    String role = 'student',
    bool keepLoggedIn = true,
  }) async {
    state = const AsyncLoading();
    _status = AuthStatus.loading;
    try {
      final responseMap = await _apiService.login(
        email: email,
        password: password,
        role: role,
      );

      final authResponse = AuthResponseModel.fromJson(responseMap);

      final userJson = authResponse.user.toJson();
      userJson['role'] = role;

      _currentUserMap = userJson;
      final updatedResponse = AuthResponseModel(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        tokenType: authResponse.tokenType,
        user: UserModel.fromJson(userJson),
      );
      _saveUserData(updatedResponse, keepLoggedIn);

      _status = AuthStatus.authenticated;
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      state = AsyncError(message, stackTrace);
      return false;
    }
  }

  /// Google Login Method with "Keep me logged in" support and Role tracking
  Future<bool> googleLogin({
    required String fullName,
    required String email,
    String? profilePicture,
    String? phoneNumber,
    String role = 'student',
    bool keepLoggedIn = true,
  }) async {
    state = const AsyncLoading();
    _status = AuthStatus.loading;
    try {
      final responseMap = await _apiService.googleLogin(
        name: fullName,
        email: email,
        profilePicture: profilePicture,
        role: role,
      );

      final authResponse = AuthResponseModel.fromJson(responseMap);

      final userJson = authResponse.user.toJson();
      userJson['role'] = role;

      _currentUserMap = userJson;
      final updatedResponse = AuthResponseModel(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        tokenType: authResponse.tokenType,
        user: UserModel.fromJson(userJson),
      );
      _saveUserData(updatedResponse, keepLoggedIn);

      // Trigger verification email request
      await _apiService.sendVerificationEmail(email: email);

      _status = AuthStatus.authenticated;
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      state = AsyncError(message, stackTrace);
      return false;
    }
  }

  /// Logout Method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(nameKey);
    await prefs.remove(emailKey);
    await prefs.remove(roleKey);
    await prefs.remove(userKey);
    await prefs.setBool(keepLoggedInKey, false);
    _currentUserMap = null;
    _status = AuthStatus.unauthenticated;
    state = const AsyncData(null);
  }
}

/// 3. StateNotifierProvider exposing AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthController(apiService);
});

// Alias for authProvider
final authProvider = authControllerProvider;
