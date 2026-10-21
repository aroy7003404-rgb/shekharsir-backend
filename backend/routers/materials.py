import os
import shutil
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

import models
import schemas
from database import get_db
from auth_deps import get_current_teacher

router = APIRouter(
    prefix="/api/materials",
    tags=["Study Materials & Notes"]
)

# Upload directory configuration
UPLOAD_DIR = os.path.join("uploads", "materials")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# 1. Fetch Study Materials (GET /api/materials)
@router.get("", response_model=List[schemas.MaterialResponse])
def get_materials(batch: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(models.StudyMaterial)
    if batch and batch != "All":
        query = query.filter(models.StudyMaterial.target_batch == batch)

    materials = query.order_by(models.StudyMaterial.upload_date.desc()).all()
    return materials


# 2. Search & Filter Study Materials (GET /api/materials/search)
@router.get("/search", response_model=List[schemas.MaterialResponse])
def search_materials(
    query: Optional[str] = None,
    type: Optional[str] = None,
    batch: Optional[str] = None,
    db: Session = Depends(get_db)
):
    q = db.query(models.StudyMaterial)

    if batch and batch != "All":
        q = q.filter(models.StudyMaterial.target_batch == batch)

    if type and type != "All":
        q = q.filter(models.StudyMaterial.file_type.ilike(f"%{type}%"))

    if query and query.strip():
        search_pattern = f"%{query.strip()}%"
        q = q.filter(
            (models.StudyMaterial.title.ilike(search_pattern)) |
            (models.StudyMaterial.description.ilike(search_pattern))
        )

    materials = q.order_by(models.StudyMaterial.upload_date.desc()).all()
    return materials


# 3. Upload Study Material (POST /api/materials/upload - Restricted to Teachers)
@router.post("/upload", response_model=schemas.MaterialResponse, status_code=status.HTTP_201_CREATED)
def upload_material(
    title: str = Form(...),
    description: Optional[str] = Form(""),
    target_batch: str = Form(...),
    file_type: str = Form("PDF"),
    file_url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_teacher: models.User = Depends(get_current_teacher)
):
    saved_file_url = file_url
    saved_file_path = None

    if file:
        filename = f"{int(datetime.utcnow().timestamp())}_{file.filename}"
        saved_file_path = os.path.join(UPLOAD_DIR, filename)
        with open(saved_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        saved_file_url = f"/static/materials/{filename}"

    new_material = models.StudyMaterial(
        title=title,
        description=description,
        target_batch=target_batch,
        file_type=file_type,
        file_url=saved_file_url,
        file_path=saved_file_path,
    )

    db.add(new_material)
    db.commit()
    db.refresh(new_material)

    return new_material
