import json
from typing import Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from datetime import datetime

import models
import schemas
from database import get_db

router = APIRouter(
    prefix="/api/classroom",
    tags=["Live Classroom & WebSockets"]
)

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


# 1. Create Live Classroom Session (POST /api/classroom/create)
@router.post("/create", response_model=schemas.ClassroomResponse, status_code=status.HTTP_201_CREATED)
def create_classroom(payload: schemas.ClassroomCreateRequest, db: Session = Depends(get_db)):
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


# 3. Real-time WebSocket Endpoint for Live Drawing, Chat & Hand Raise
@router.websocket("/ws/{classroom_id}")
async def websocket_classroom_endpoint(websocket: WebSocket, classroom_id: str):
    await manager.connect(classroom_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            event_type = data.get("event")  # 'whiteboard_draw', 'chat_message', 'hand_raise'

            if event_type == "whiteboard_draw":
                # Broadcast stroke coordinates to all participants in room
                await manager.broadcast(classroom_id, {
                    "event": "whiteboard_draw",
                    "points": data.get("points"),
                    "color": data.get("color"),
                    "stroke_width": data.get("stroke_width"),
                })
            elif event_type == "chat_message":
                # Broadcast live chat message
                await manager.broadcast(classroom_id, {
                    "event": "chat_message",
                    "sender": data.get("sender"),
                    "text": data.get("text"),
                    "time": data.get("time"),
                    "is_teacher": data.get("is_teacher", False),
                })
            elif event_type == "hand_raise":
                # Broadcast hand raise alert to teacher sockets
                await manager.broadcast(classroom_id, {
                    "event": "hand_raise",
                    "student_name": data.get("student_name"),
                    "student_id": data.get("student_id"),
                    "message": f"{data.get('student_name', 'A student')} raised their hand!",
                })
            else:
                # Generic fallback broadcast
                await manager.broadcast(classroom_id, data)

    except WebSocketDisconnect:
        manager.disconnect(classroom_id, websocket)
