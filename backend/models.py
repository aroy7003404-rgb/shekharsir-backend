from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True)
    role = Column(String, default="student", nullable=False)  # 'student' or 'teacher'
    is_email_verified = Column(Boolean, default=False, nullable=False)
    verification_code = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    submissions = relationship("TestSubmission", back_populates="student", cascade="all, delete-orphan")


class UserDeviceToken(Base):
    __tablename__ = "user_device_tokens"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    fcm_token = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class Test(Base):
    __tablename__ = "tests"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    target_batch = Column(String, nullable=False)
    duration_minutes = Column(Integer, default=60, nullable=False)
    total_marks = Column(Integer, default=50, nullable=False)
    due_date = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    questions = relationship("Question", back_populates="test", cascade="all, delete-orphan")
    submissions = relationship("TestSubmission", back_populates="test", cascade="all, delete-orphan")


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    question_text = Column(Text, nullable=False)
    type = Column(String, default="MCQ", nullable=False)  # 'MCQ', 'TrueFalse', 'ShortAnswer'
    marks = Column(Integer, default=5, nullable=False)
    options = Column(JSON, nullable=True)  # List of option strings for MCQ
    correct_answer = Column(Text, nullable=True)

    test = relationship("Test", back_populates="questions")


class TestSubmission(Base):
    __tablename__ = "test_submissions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    answers = Column(JSON, nullable=False)  # List of student's answers
    score = Column(Float, default=0.0, nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    test = relationship("Test", back_populates="submissions")
    student = relationship("User", back_populates="submissions")


class StudyMaterial(Base):
    __tablename__ = "study_materials"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    target_batch = Column(String, nullable=False)
    file_type = Column(String, default="PDF", nullable=False)  # 'PDF', 'Document', 'Link', 'Video'
    file_url = Column(String, nullable=True)
    file_path = Column(String, nullable=True)
    uploaded_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    upload_date = Column(DateTime, default=datetime.utcnow, nullable=False)


class AttendanceSession(Base):
    __tablename__ = "attendance_sessions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    batch_name = Column(String, nullable=False)
    date = Column(String, nullable=False)
    total_students = Column(Integer, default=0)
    present_count = Column(Integer, default=0)
    absent_count = Column(Integer, default=0)
    late_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    records = relationship("StudentAttendanceRecord", back_populates="session", cascade="all, delete-orphan")


class StudentAttendanceRecord(Base):
    __tablename__ = "student_attendance_records"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    session_id = Column(Integer, ForeignKey("attendance_sessions.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(String, nullable=True)
    roll_number = Column(String, nullable=True)
    name = Column(String, nullable=False)
    status = Column(String, nullable=False)  # 'Present', 'Absent', 'Late'

    session = relationship("AttendanceSession", back_populates="records")


class LiveClassroom(Base):
    __tablename__ = "live_classrooms"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    target_batch = Column(String, nullable=False)
    room_token = Column(String, unique=True, index=True, nullable=False)
    is_active = Column(String, default="active", nullable=False)  # 'active' or 'ended'
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    recordings = relationship("ClassroomRecording", back_populates="classroom", cascade="all, delete-orphan")
    attendances = relationship("ClassroomAttendance", back_populates="classroom", cascade="all, delete-orphan")


class ClassroomRecording(Base):
    __tablename__ = "classroom_recordings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    classroom_id = Column(Integer, ForeignKey("live_classrooms.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    file_type = Column(String, default="Video", nullable=False)
    file_url = Column(String, nullable=True)
    file_path = Column(String, nullable=True)
    upload_date = Column(DateTime, default=datetime.utcnow, nullable=False)

    classroom = relationship("LiveClassroom", back_populates="recordings")


class ClassroomAttendance(Base):
    __tablename__ = "classroom_attendances"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    classroom_id = Column(Integer, ForeignKey("live_classrooms.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(String, nullable=True)
    student_name = Column(String, nullable=False)
    joined_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    left_at = Column(DateTime, nullable=True)
    duration_minutes = Column(Float, default=0.0)
    status = Column(String, default="Present", nullable=False)  # 'Present', 'Late'

    classroom = relationship("LiveClassroom", back_populates="attendances")


class StorageFile(Base):
    __tablename__ = "storage_files"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    object_key = Column(String, unique=True, index=True, nullable=False)
    filename = Column(String, nullable=False)
    mime_type = Column(String, default="application/pdf", nullable=False)
    file_size_bytes = Column(Integer, default=0, nullable=False)
    uploader_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    classroom_id = Column(Integer, ForeignKey("live_classrooms.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
