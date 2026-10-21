class ClassroomMaterialModel {
  final int id;
  final int classroomId;
  final String title;
  final String description;
  final String fileType;
  final String? fileUrl;
  final String uploadDate;

  ClassroomMaterialModel({
    required this.id,
    required this.classroomId,
    required this.title,
    required this.description,
    required this.fileType,
    this.fileUrl,
    required this.uploadDate,
  });

  factory ClassroomMaterialModel.fromJson(Map<String, dynamic> json) {
    return ClassroomMaterialModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      classroomId: json['classroom_id'] is int ? json['classroom_id'] : int.tryParse(json['classroom_id']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'Classroom Recording',
      description: json['description'] ?? '',
      fileType: json['file_type'] ?? 'Video',
      fileUrl: json['file_url']?.toString(),
      uploadDate: json['upload_date']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'title': title,
      'description': description,
      'file_type': fileType,
      'file_url': fileUrl,
      'upload_date': uploadDate,
    };
  }
}
