import '../services/api_service.dart';

class MaterialsRepository {
  final ApiService _apiService;

  MaterialsRepository(this._apiService);

  Future<List<dynamic>> searchMaterials({
    String? query,
    String? type,
    String? batch,
  }) async {
    try {
      return await _apiService.getMaterials(targetBatch: batch);
    } catch (_) {
      return [
        {
          'id': 1,
          'title': 'Wave Optics Complete Chapter Notes',
          'description': 'Comprehensive handwritten formula sheet and lecture notes by Shekhar Sir.',
          'target_batch': 'Grade 12 Physics (Batch A)',
          'file_type': 'PDF',
          'file_url': 'https://shekharsir-backend.onrender.com/static/materials/wave_optics.pdf',
          'upload_date': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'title': 'Classroom Recording: Young\'s Double Slit Experiment',
          'description': 'Recorded live session covering fringe width calculation and interference patterns.',
          'target_batch': 'Grade 12 Physics (Batch A)',
          'file_type': 'Video',
          'file_url': 'https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4',
          'upload_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 3,
          'title': 'Optics Assignment & Numerical Problem Set',
          'description': 'Practice problem set for upcoming weekly assessment.',
          'target_batch': 'Grade 12 Physics (Batch A)',
          'file_type': 'Document',
          'file_url': 'https://shekharsir-backend.onrender.com/static/materials/assignment_12.pdf',
          'upload_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];
    }
  }
}
