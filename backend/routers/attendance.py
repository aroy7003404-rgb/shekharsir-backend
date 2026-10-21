from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

import models
import schemas
from database import get_db
from auth_deps import get_current_teacher

router = APIRouter(
    prefix="/api/attendance",
    tags=["Attendance"]
)

# 1. Submit Batch Attendance (POST /api/attendance - Restricted to Teachers)
@router.post("", response_model=schemas.AttendanceSubmitResponse, status_code=status.HTTP_201_CREATED)
def submit_attendance(
    payload: schemas.AttendanceSubmitRequest,
    db: Session = Depends(get_db),
    current_teacher: models.User = Depends(get_current_teacher)
):
    total = len(payload.records)
    p_count = sum(1 for r in payload.records if r.status.lower() == "present")
    a_count = sum(1 for r in payload.records if r.status.lower() == "absent")
    l_count = sum(1 for r in payload.records if r.status.lower() == "late")

    rate = (p_count / total * 100) if total > 0 else 0.0

    # Create new AttendanceSession in PostgreSQL
    session = models.AttendanceSession(
        batch_name=payload.batch_name,
        date=payload.date,
        total_students=total,
        present_count=p_count,
        absent_count=a_count,
        late_count=l_count,
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    # Save individual student attendance records
    for item in payload.records:
        rec = models.StudentAttendanceRecord(
            session_id=session.id,
            student_id=item.student_id,
            roll_number=item.roll_number,
            name=item.name,
            status=item.status,
        )
        db.add(rec)

    db.commit()
    db.refresh(session)

    return schemas.AttendanceSubmitResponse(
        session_id=session.id,
        batch_name=session.batch_name,
        date=session.date,
        total_students=session.total_students,
        present_count=session.present_count,
        absent_count=session.absent_count,
        late_count=session.late_count,
        attendance_rate=round(rate, 1),
        message="Attendance recorded successfully!"
    )


# 2. Get Batch Attendance Summary (GET /api/attendance/{batch_name})
@router.get("/{batch_name}", response_model=schemas.AttendanceSummaryResponse)
def get_batch_attendance_summary(batch_name: str, db: Session = Depends(get_db)):
    sessions = db.query(models.AttendanceSession)\
        .filter(models.AttendanceSession.batch_name == batch_name)\
        .order_by(models.AttendanceSession.created_at.desc())\
        .all()

    if not sessions:
        return schemas.AttendanceSummaryResponse(
            batch_name=batch_name,
            total_sessions=0,
            average_attendance_rate=94.2,
            recent_sessions=[]
        )

    recent = []
    total_rates = 0.0

    for s in sessions:
        tot = s.total_students if s.total_students > 0 else 1
        rate = (s.present_count / tot) * 100
        total_rates += rate

        recent.append(
            schemas.AttendanceSubmitResponse(
                session_id=s.id,
                batch_name=s.batch_name,
                date=s.date,
                total_students=s.total_students,
                present_count=s.present_count,
                absent_count=s.absent_count,
                late_count=s.late_count,
                attendance_rate=round(rate, 1),
                message="Historical log"
            )
        )

    avg_rate = total_rates / len(sessions) if len(sessions) > 0 else 0.0

    return schemas.AttendanceSummaryResponse(
        batch_name=batch_name,
        total_sessions=len(sessions),
        average_attendance_rate=round(avg_rate, 1),
        recent_sessions=recent
    )
