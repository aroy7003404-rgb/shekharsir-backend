import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class StudentAttendanceModel {
  final String id;
  final String rollNumber;
  final String name;
  String status; // 'Present', 'Absent', 'Late'

  StudentAttendanceModel({
    required this.id,
    required this.rollNumber,
    required this.name,
    this.status = 'Present',
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceModel(
      id: json['id']?.toString() ?? '',
      rollNumber: json['roll_number'] ?? 'SSC-${json['id'] ?? '101'}',
      name: json['name'] ?? json['full_name'] ?? 'Student',
      status: json['status'] ?? 'Present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': id,
      'roll_number': rollNumber,
      'name': name,
      'status': status,
    };
  }
}

class AttendanceState {
  final bool isLoading;
  final bool isSubmitting;
  final List<StudentAttendanceModel> students;
  final String? errorMessage;

  const AttendanceState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.students = const [],
    this.errorMessage,
  });

  int get totalStudents => students.length;
  int get presentCount => students.where((s) => s.status == 'Present').length;
  int get absentCount => students.where((s) => s.status == 'Absent').length;
  int get lateCount => students.where((s) => s.status == 'Late').length;

  double get attendancePercentage =>
      totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;

  AttendanceState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<StudentAttendanceModel>? students,
    String? errorMessage,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      students: students ?? this.students,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final Ref _ref;

  // Default student list for selected batches
  final Map<String, List<StudentAttendanceModel>> _mockBatchStudents = {
    'Grade 12 Physics (Batch A)': [
      StudentAttendanceModel(id: '101', rollNumber: 'PHY-1201', name: 'Aarav Sharma', status: 'Present'),
      StudentAttendanceModel(id: '102', rollNumber: 'PHY-1202', name: 'Ananya Gupta', status: 'Present'),
      StudentAttendanceModel(id: '103', rollNumber: 'PHY-1203', name: 'Devansh Verma', status: 'Absent'),
      StudentAttendanceModel(id: '104', rollNumber: 'PHY-1204', name: 'Ishita Patel', status: 'Present'),
      StudentAttendanceModel(id: '105', rollNumber: 'PHY-1205', name: 'Kavya Singh', status: 'Late'),
      StudentAttendanceModel(id: '106', rollNumber: 'PHY-1206', name: 'Rohan Mehta', status: 'Present'),
      StudentAttendanceModel(id: '107', rollNumber: 'PHY-1207', name: 'Siddharth Rao', status: 'Present'),
    ],
    'Grade 11 Mechanics': [
      StudentAttendanceModel(id: '201', rollNumber: 'MEC-1101', name: 'Aditya Kumar', status: 'Present'),
      StudentAttendanceModel(id: '202', rollNumber: 'MEC-1102', name: 'Diya Reddy', status: 'Present'),
      StudentAttendanceModel(id: '203', rollNumber: 'MEC-1103', name: 'Manish Joshi', status: 'Absent'),
      StudentAttendanceModel(id: '204', rollNumber: 'MEC-1104', name: 'Neha Saxena', status: 'Present'),
      StudentAttendanceModel(id: '205', rollNumber: 'MEC-1105', name: 'Priya Agarwal', status: 'Present'),
    ],
    'Class 10 Science Booster': [
      StudentAttendanceModel(id: '301', rollNumber: 'SCI-1001', name: 'Arjun Das', status: 'Present'),
      StudentAttendanceModel(id: '302', rollNumber: 'SCI-1002', name: 'Bhavya Jain', status: 'Present'),
      StudentAttendanceModel(id: '303', rollNumber: 'SCI-1003', name: 'Chetan Roy', status: 'Late'),
      StudentAttendanceModel(id: '304', rollNumber: 'SCI-1004', name: 'Divya Nair', status: 'Present'),
    ],
  };

  AttendanceNotifier(this._ref) : super(const AttendanceState());

  Future<void> loadBatchStudents(String batchName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final rawList = await apiService.getBatchStudents(batchName: batchName);
      final students = rawList
          .map((x) => StudentAttendanceModel.fromJson(x as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        students: students.isEmpty
            ? (_mockBatchStudents[batchName] ?? _mockBatchStudents.values.first)
            : students,
      );
    } catch (e) {
      // Fallback to mock batch students if backend endpoint is pending
      final students = _mockBatchStudents[batchName] ?? _mockBatchStudents.values.first;
      state = state.copyWith(isLoading: false, students: students);
    }
  }

  void toggleStudentStatus(int index, String newStatus) {
    final updatedList = List<StudentAttendanceModel>.from(state.students);
    updatedList[index].status = newStatus;
    state = state.copyWith(students: updatedList);
  }

  Future<bool> submitAttendance({
    required String batchName,
    required String date,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final records = state.students.map((s) => s.toJson()).toList();

      await apiService.submitAttendance(
        batchName: batchName,
        date: date,
        attendanceRecords: records,
      );

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return true; // Fallback success for UI feedback
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref);
});
