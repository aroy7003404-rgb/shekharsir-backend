from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, JSON, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True)  # Nullable for Google Auth
    role = Column(String, default="student", nullable=False)  # 'student' or 'teacher'
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    tests_created = relationship("Test", back_populates="creator")
    submissions = relationship("TestSubmission", back_populates="student")


class Test(Base):
    __tablename__ = "tests"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    target_batch = Column(String, nullable=False)
    duration_minutes = Column(Integer, default=60, nullable=False)
    total_marks = Column(Integer, default=50, nullable=False)
    due_date = Column(String, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    creator = relationship("User", back_populates="tests_created")
    questions = relationship("Question", back_populates="test", cascade="all, delete-orphan")
    submissions = relationship("TestSubmission", back_populates="test", cascade="all, delete-orphan")


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    question_text = Column(Text, nullable=False)
    type = Column(String, default="MCQ", nullable=False)  # 'MCQ' or 'Subjective'
    marks = Column(Integer, default=5, nullable=False)
    options = Column(JSON, nullable=True)  # List of option strings
    correct_answer = Column(String, nullable=True)

    test = relationship("Test", back_populates="questions")


class TestSubmission(Base):
    __tablename__ = "test_submissions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    student_name = Column(String, nullable=True)
    answers = Column(JSON, nullable=False)  # List of student answers
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
    file_type = Column(String, default="PDF", nullable=False)  # 'PDF', 'Document', 'Link'
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
    status = Column(String, default="Present", nullable=False)  # 'Present', 'Absent', 'Late'

    session = relationship("AttendanceSession", back_populates="records")


class LiveClassroom(Base):
    __tablename__ = "live_classrooms"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    target_batch = Column(String, nullable=False)
    room_token = Column(String, unique=True, index=True, nullable=False)
    is_active = Column(String, default="active", nullable=False)  # 'active' or 'ended'
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
