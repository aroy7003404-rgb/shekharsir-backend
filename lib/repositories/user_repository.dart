import '../services/api_service.dart';

class UserRepository {
  UserRepository(ApiService apiService);

  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      return {
        'id': 1,
        'name': 'Aarav Sharma',
        'email': 'aarav.sharma@shekharsir.edu',
        'role': 'student',
        'is_email_verified': true,
      };
    } catch (e) {
      throw Exception('Failed to load profile details.');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String email,
  }) async {
    try {
      return {
        'id': 1,
        'name': name,
        'email': email,
        'role': 'student',
        'is_email_verified': true,
      };
    } catch (e) {
      throw Exception('Failed to update profile details.');
    }
  }
}
