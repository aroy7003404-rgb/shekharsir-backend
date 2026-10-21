from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

import models
from database import get_db
from services.storage import storage_service
from auth_deps import get_current_user

router = APIRouter(
    prefix="/api/storage",
    tags=["Cloud Storage & Pre-signed URLs"]
)

# 1. Pre-signed PUT Upload URL Endpoint (POST /api/storage/upload-url)
@router.post("/upload-url")
def get_presigned_upload_url(
    payload: dict,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    filename = payload.get("filename", "document.pdf")
    mime_type = payload.get("mime_type", "application/pdf")
    classroom_id = payload.get("classroom_id")

    object_key = f"uploads/{current_user.id}/{int(datetime.utcnow().timestamp())}_{filename}"

    result = storage_service.generate_presigned_upload_url(
        object_key=object_key,
        content_type=mime_type,
        expires_in=3600
    )

    # Track object key in PostgreSQL database
    new_storage_file = models.StorageFile(
        object_key=object_key,
        filename=filename,
        mime_type=mime_type,
        uploader_id=current_user.id,
        classroom_id=classroom_id
    )
    db.add(new_storage_file)
    db.commit()

    return result


# 2. Pre-signed GET Download URL Endpoint (GET /api/storage/download-url)
@router.get("/download-url")
def get_presigned_download_url(
    object_key: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    return storage_service.generate_presigned_download_url(
        object_key=object_key,
        expires_in=3600
    )
