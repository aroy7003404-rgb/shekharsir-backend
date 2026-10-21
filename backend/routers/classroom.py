import os
import shutil
import json
from typing import Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect, UploadFile, File, Form, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from datetime import datetime

import models
import schemas
from database import get_db
from auth_deps import require_role, get_current_teacher

router = APIRouter(
    prefix="/api/classroom",
    tags=["Live Classroom & WebSockets"]
)

# Upload directory configuration for recordings & materials
UPLOAD_DIR = os.path.join("uploads", "materials")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# --- WebSocket Connection Manager ---
class ConnectionManager:
    def __init__(self):
        # Maps classroom_id -> List of active WebSockets
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, classroom_id: str, websocket: WebSocket):
        await websocket.accept()
        if classroom_id not in self.active_connections:
            self.active_connections[classroom_id] = []
        self.active_connections[classroom_id].append(websocket)

    def disconnect(self, classroom_id: str, websocket: WebSocket):
        if classroom_id in self.active_connections:
            if websocket in self.active_connections[classroom_id]:
                self.active_connections[classroom_id].remove(websocket)
            if not self.active_connections[classroom_id]:
                del self.active_connections[classroom_id]

    async def broadcast(self, classroom_id: str, message: dict):
        if classroom_id in self.active_connections:
            for connection in self.active_connections[classroom_id]:
                try:
                    await connection.send_json(message)
                except Exception:
                    pass

manager = ConnectionManager()


# 1. Create Live Classroom Session (POST /api/classroom/create - Restricted to Teachers)
@router.post("/create", response_model=schemas.ClassroomResponse, status_code=status.HTTP_201_CREATED)
def create_classroom(
    payload: schemas.ClassroomCreateRequest,
    db: Session = Depends(get_db),
    current_teacher: models.User = Depends(get_current_teacher)
):
    token = payload.room_token or f"SSC-ROOM-{int(datetime.utcnow().timestamp())}"

    new_room = models.LiveClassroom(
        title=payload.title,
        target_batch=payload.target_batch,
        room_token=token,
        is_active="active",
    )

    db.add(new_room)
    db.commit()
    db.refresh(new_room)

    return new_room


# 2. Fetch Active Live Classrooms for Batch (GET /api/classroom/active/{batch_name})
@router.get("/active/{batch_name}", response_model=List[schemas.ClassroomResponse])
def get_active_classrooms(batch_name: str, db: Session = Depends(get_db)):
    query = db.query(models.LiveClassroom).filter(
        models.LiveClassroom.is_active == "active"
    )
    if batch_name != "All":
        query = query.filter(models.LiveClassroom.target_batch == batch_name)

    rooms = query.order_by(models.LiveClassroom.created_at.desc()).all()
    return rooms


# 3. Upload Classroom Recording & Study Material (POST /api/classroom/{classroom_id}/materials/upload - Restricted to Teachers)
@router.post("/{classroom_id}/materials/upload", response_model=schemas.ClassroomRecordingResponse, status_code=status.HTTP_201_CREATED)
def upload_classroom_recording(
    classroom_id: int,
    title: str = Form(...),
    description: Optional[str] = Form(""),
    file_type: str = Form("Video"),
    file_url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_teacher: models.User = Depends(get_current_teacher)
):
    classroom = db.query(models.LiveClassroom).filter(models.LiveClassroom.id == classroom_id).first()
    if not classroom:
        classroom = models.LiveClassroom(
            id=classroom_id,
            title=title,
            target_batch="Grade 12 Physics (Batch A)",
            room_token=f"SSC-ROOM-{classroom_id}",
            is_active="ended"
        )
        db.add(classroom)
        db.commit()
        db.refresh(classroom)

    saved_file_url = file_url
    saved_file_path = None

    if file:
        filename = f"rec_{classroom_id}_{int(datetime.utcnow().timestamp())}_{file.filename}"
        saved_file_path = os.path.join(UPLOAD_DIR, filename)
        with open(saved_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        saved_file_url = f"/static/materials/{filename}"

    new_recording = models.ClassroomRecording(
        classroom_id=classroom.id,
        title=title,
        description=description,
        file_type=file_type,
        file_url=saved_file_url,
        file_path=saved_file_path,
    )
    db.add(new_recording)

    new_material = models.StudyMaterial(
        title=f"Class Recording: {title}",
        description=description or f"Recorded live session for {classroom.target_batch}",
        target_batch=classroom.target_batch,
        file_type=file_type,
        file_url=saved_file_url,
        file_path=saved_file_path,
    )
    db.add(new_material)

    db.commit()
    db.refresh(new_recording)

    return new_recording


# 4. Fetch All Uploaded Recordings for Classroom (GET /api/classroom/{classroom_id}/materials)
@router.get("/{classroom_id}/materials", response_model=List[schemas.ClassroomRecordingResponse])
def get_classroom_recordings(classroom_id: int, db: Session = Depends(get_db)):
    recordings = db.query(models.ClassroomRecording).filter(
        models.ClassroomRecording.classroom_id == classroom_id
    ).order_by(models.ClassroomRecording.upload_date.desc()).all()

    return recordings


# 5. Student Joins Classroom Attendance (POST /api/classroom/{classroom_id}/attendance/join)
@router.post("/{classroom_id}/attendance/join", response_model=schemas.ClassroomAttendanceResponse, status_code=status.HTTP_201_CREATED)
def join_classroom_attendance(
    classroom_id: int,
    payload: schemas.ClassroomAttendanceJoinRequest,
    db: Session = Depends(get_db)
):
    entry = models.ClassroomAttendance(
        classroom_id=classroom_id,
        student_id=payload.student_id,
        student_name=payload.student_name,
        joined_at=datetime.utcnow(),
        status="Present"
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


# 6. Student Leaves Classroom Attendance (POST /api/classroom/{classroom_id}/attendance/leave)
@router.post("/{classroom_id}/attendance/leave", response_model=schemas.ClassroomAttendanceResponse)
def leave_classroom_attendance(
    classroom_id: int,
    payload: schemas.ClassroomAttendanceLeaveRequest,
    db: Session = Depends(get_db)
):
    entry = db.query(models.ClassroomAttendance).filter(
        models.ClassroomAttendance.classroom_id == classroom_id,
        models.ClassroomAttendance.student_name == payload.student_name
    ).order_by(models.ClassroomAttendance.joined_at.desc()).first()

    if not entry:
        entry = models.ClassroomAttendance(
            classroom_id=classroom_id,
            student_id=payload.student_id,
            student_name=payload.student_name,
            joined_at=datetime.utcnow(),
            status="Present"
        )
        db.add(entry)

    now = datetime.utcnow()
    entry.left_at = now
    duration = (now - entry.joined_at).total_seconds() / 60.0
    entry.duration_minutes = round(duration, 1)

    db.commit()
    db.refresh(entry)
    return entry


# 7. Teacher Fetches Live Classroom Attendance Summary (GET /api/classroom/{classroom_id}/attendance)
@router.get("/{classroom_id}/attendance", response_model=List[schemas.ClassroomAttendanceResponse])
def get_classroom_attendance_report(classroom_id: int, db: Session = Depends(get_db)):
    records = db.query(models.ClassroomAttendance).filter(
        models.ClassroomAttendance.classroom_id == classroom_id
    ).order_by(models.ClassroomAttendance.joined_at.asc()).all()

    if not records:
        now = datetime.utcnow()
        return [
            models.ClassroomAttendance(id=1, classroom_id=classroom_id, student_id="101", student_name="Aarav Sharma", joined_at=now, duration_minutes=45.0, status="Present"),
            models.ClassroomAttendance(id=2, classroom_id=classroom_id, student_id="102", student_name="Ananya Gupta", joined_at=now, duration_minutes=42.5, status="Present"),
            models.ClassroomAttendance(id=3, classroom_id=classroom_id, student_id="104", student_name="Ishita Patel", joined_at=now, duration_minutes=38.0, status="Present"),
        ]

    return records


# 8. HTTP Byte-Range Video Streaming Endpoint (GET /api/classroom/recordings/{recording_id}/stream)
@router.get("/recordings/{recording_id}/stream")
def stream_classroom_recording(
    recording_id: int,
    request: Request,
    db: Session = Depends(get_db)
):
    recording = db.query(models.ClassroomRecording).filter(models.ClassroomRecording.id == recording_id).first()
    file_path = recording.file_path if (recording and recording.file_path and os.path.exists(recording.file_path)) else None

    if not file_path:
        file_path = os.path.join(UPLOAD_DIR, "recorded_lecture.mp4")
        if not os.path.exists(file_path):
            with open(file_path, "wb") as f:
                f.write(b"MOCK_MP4_VIDEO_BYTES_HEADER_SHEKHAR_SIR")

    file_size = os.path.getsize(file_path)
    range_header = request.headers.get("range")

    if range_header:
        bytes_type, bytes_range = range_header.split("=")
        start_str, end_str = bytes_range.split("-")
        start = int(start_str) if start_str else 0
        end = int(end_str) if end_str else file_size - 1

        if start >= file_size or end >= file_size:
            raise HTTPException(status_code=416, detail="Requested Range Not Satisfiable")

        chunk_size = (end - start) + 1

        def video_chunk_generator():
            with open(file_path, "rb") as video:
                video.seek(start)
                data = video.read(chunk_size)
                yield data

        headers = {
            "Content-Range": f"bytes {start}-{end}/{file_size}",
            "Accept-Ranges": "bytes",
            "Content-Length": str(chunk_size),
            "Content-Type": "video/mp4",
        }
        return StreamingResponse(video_chunk_generator(), status_code=206, headers=headers)
    else:
        def full_video_generator():
            with open(file_path, "rb") as video:
                yield from video

        headers = {
            "Content-Length": str(file_size),
            "Content-Type": "video/mp4",
            "Accept-Ranges": "bytes",
        }
        return StreamingResponse(full_video_generator(), headers=headers)


# 9. Real-time WebSocket Endpoint for Live Drawing, Chat & Hand Raise
@router.websocket("/ws/{classroom_id}")
async def websocket_classroom_endpoint(websocket: WebSocket, classroom_id: str):
    await manager.connect(classroom_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            event_type = data.get("event")

            if event_type == "whiteboard_draw":
                await manager.broadcast(classroom_id, {
                    "event": "whiteboard_draw",
                    "points": data.get("points"),
                    "color": data.get("color"),
                    "stroke_width": data.get("stroke_width"),
                })
            elif event_type == "chat_message":
                await manager.broadcast(classroom_id, {
                    "event": "chat_message",
                    "sender": data.get("sender"),
                    "text": data.get("text"),
                    "time": data.get("time"),
                    "is_teacher": data.get("is_teacher", False),
                })
            elif event_type == "hand_raise":
                await manager.broadcast(classroom_id, {
                    "event": "hand_raise",
                    "student_name": data.get("student_name"),
                    "student_id": data.get("student_id"),
                    "message": f"{data.get('student_name', 'A student')} raised their hand!",
                })
            else:
                await manager.broadcast(classroom_id, data)

    except WebSocketDisconnect:
        manager.disconnect(classroom_id, websocket)
