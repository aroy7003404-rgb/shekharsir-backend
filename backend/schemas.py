from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any, Dict
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: Optional[str] = "student"

class UserLogin(BaseModel):
    email: EmailStr
    password: str
    role: Optional[str] = "student"

class GoogleLoginRequest(BaseModel):
    name: str
    email: EmailStr
    profile_picture: Optional[str] = None
    role: Optional[str] = "student"

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    is_email_verified: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class AuthTokenResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    user: UserResponse

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class RefreshTokenResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"


# --- Email Verification Schemas ---

class SendEmailVerificationRequest(BaseModel):
    email: EmailStr

class EmailVerifyRequest(BaseModel):
    email: EmailStr
    code: str

class EmailVerifyResponse(BaseModel):
    success: bool
    message: str
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: Optional[str] = "bearer"
    user: Optional[Dict[str, Any]] = None


# --- Test & Question Schemas ---

class QuestionCreate(BaseModel):
    question_text: str
    type: Optional[str] = "MCQ"
    marks: Optional[int] = 5
    options: Optional[List[str]] = []
    correct_answer: Optional[str] = ""

class QuestionResponse(BaseModel):
    id: int
    question_text: str
    type: str
    marks: int
    options: Optional[List[str]] = []

    class Config:
        from_attributes = True

class TestCreate(BaseModel):
    title: str
    subject: str
    target_batch: str
    duration_minutes: Optional[int] = 60
    total_marks: Optional[int] = 50
    due_date: Optional[str] = None
    questions: List[QuestionCreate]

class TestResponse(BaseModel):
    id: int
    title: str
    subject: str
    target_batch: str
    duration_minutes: int
    total_marks: int
    due_date: Optional[str] = None
    created_at: datetime
    questions: List[QuestionResponse] = []

    class Config:
        from_attributes = True

class StudentAnswerItem(BaseModel):
    question_index: int
    answer: str

class TestSubmitRequest(BaseModel):
    test_id: str
    answers: List[StudentAnswerItem]

class TestSubmitResponse(BaseModel):
    test_id: str
    score: float
    total_marks: int
    percentage: float
    message: str


# --- Study Material Schemas ---

class MaterialResponse(BaseModel):
    id: int
    title: str
    description: Optional[str] = ""
    target_batch: str
    file_type: str
    file_url: Optional[str] = None
    upload_date: datetime

    class Config:
        from_attributes = True


# --- Attendance Schemas ---

class AttendanceRecordItem(BaseModel):
    student_id: Optional[str] = ""
    roll_number: Optional[str] = ""
    name: str
    status: str  # 'Present', 'Absent', 'Late'

class AttendanceSubmitRequest(BaseModel):
    batch_name: str
    date: str
    records: List[AttendanceRecordItem]

class AttendanceSubmitResponse(BaseModel):
    session_id: int
    batch_name: str
    date: str
    total_students: int
    present_count: int
    absent_count: int
    late_count: int
    attendance_rate: float
    message: str

class AttendanceSummaryResponse(BaseModel):
    batch_name: str
    total_sessions: int
    average_attendance_rate: float
    recent_sessions: List[AttendanceSubmitResponse] = []


# --- Live Classroom, Recording & Live Attendance Schemas ---

class ClassroomCreateRequest(BaseModel):
    title: str
    target_batch: str
    room_token: Optional[str] = None

class ClassroomResponse(BaseModel):
    id: int
    title: str
    target_batch: str
    room_token: str
    is_active: str
    created_at: datetime

    class Config:
        from_attributes = True

class ClassroomRecordingResponse(BaseModel):
    id: int
    classroom_id: int
    title: str
    description: Optional[str] = ""
    file_type: str
    file_url: Optional[str] = None
    upload_date: datetime

    class Config:
        from_attributes = True

class ClassroomAttendanceJoinRequest(BaseModel):
    student_id: Optional[str] = ""
    student_name: str

class ClassroomAttendanceLeaveRequest(BaseModel):
    student_id: Optional[str] = ""
    student_name: str

class ClassroomAttendanceResponse(BaseModel):
    id: int
    classroom_id: int
    student_id: Optional[str] = ""
    student_name: str
    joined_at: datetime
    left_at: Optional[datetime] = None
    duration_minutes: float
    status: str

    class Config:
        from_attributes = True
