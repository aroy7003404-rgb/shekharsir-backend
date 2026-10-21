import os
import sys
import logging
from passlib.context import CryptContext
from sqlalchemy.orm import Session

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import models
from database import engine, SessionLocal, Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ADMIN_NAME = os.getenv("ADMIN_NAME", "Shekhar Sir (Admin)")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "shekhar.sir@shekharsir.edu")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "ShekharSir2026!")

SUBJECT_CATEGORIES = [
    {"title": "Physics Complete Course Notes", "subject": "Physics", "target_batch": "Grade 12 Physics (Batch A)"},
    {"title": "Chemistry Formula & Reaction Guide", "subject": "Chemistry", "target_batch": "Grade 12 Chemistry"},
    {"title": "Mathematics Calculus Problem Set", "subject": "Mathematics", "target_batch": "Grade 12 Mathematics"},
    {"title": "Computer Science Python Data Structures", "subject": "Computer Science", "target_batch": "Grade 12 CS"},
]

def seed_database():
    """Idempotent database seeding script."""
    logger.info("Initializing database tables...")
    Base.metadata.create_all(bind=engine)

    db: Session = SessionLocal()
    try:
        # 1. Seed Super-Teacher Admin Account
        admin_user = db.query(models.User).filter(models.User.email == ADMIN_EMAIL).first()
        if not admin_user:
            hashed_password = pwd_context.hash(ADMIN_PASSWORD)
            admin_user = models.User(
                name=ADMIN_NAME,
                email=ADMIN_EMAIL,
                password_hash=hashed_password,
                role="teacher",
                is_email_verified=True,
            )
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
            logger.info(f"Created default teacher admin account: {ADMIN_EMAIL}")
        else:
            logger.info(f"Teacher admin account already exists: {ADMIN_EMAIL}")

        # 2. Seed Default Student Account
        student_email = "student@shekharsir.edu"
        student_user = db.query(models.User).filter(models.User.email == student_email).first()
        if not student_user:
            student_user = models.User(
                name="Aarav Sharma",
                email=student_email,
                password_hash=pwd_context.hash("StudentPass123!"),
                role="student",
                is_email_verified=True,
            )
            db.add(student_user)
            db.commit()
            logger.info(f"Created default student account: {student_email}")

        # 3. Seed Core Subject Course Categories & Study Materials
        for cat in SUBJECT_CATEGORIES:
            existing_mat = db.query(models.StudyMaterial).filter(models.StudyMaterial.title == cat["title"]).first()
            if not existing_mat:
                new_mat = models.StudyMaterial(
                    title=cat["title"],
                    description=f"Core curriculum materials for {cat['subject']}.",
                    target_batch=cat["target_batch"],
                    file_type="PDF",
                    file_url=f"https://shekharsir-backend.onrender.com/static/materials/{cat['subject'].lower()}_notes.pdf"
                )
                db.add(new_mat)
        db.commit()
        logger.info("Pre-populated core subject course categories (Mathematics, Physics, Chemistry, Computer Science).")

        # 4. Seed Default Live Classroom Session
        default_classroom = db.query(models.LiveClassroom).filter(models.LiveClassroom.title == "Physics: Wave Optics Interference").first()
        if not default_classroom:
            default_classroom = models.LiveClassroom(
                title="Physics: Wave Optics Interference",
                target_batch="Grade 12 Physics (Batch A)",
                room_token="SSC-ROOM-84920",
                is_active="active"
            )
            db.add(default_classroom)
            db.commit()
            logger.info("Created default live classroom session SSC-ROOM-84920.")

        logger.info("Database seeding completed successfully with zero duplicate key errors.")

    except Exception as e:
        db.rollback()
        logger.error(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
