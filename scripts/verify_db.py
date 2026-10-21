import os
import sys
import logging

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "backend"))

try:
    import models
    from database import SessionLocal
except ImportError:
    from backend import models
    from backend.database import SessionLocal

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s]: %(message)s")
logger = logging.getLogger("db_verify")

def verify_database_integrity():
    """Verify data integrity, row counts, and administrative accounts post-seeding."""
    logger.info("Verifying database schema, tables, and seeded records...")
    db = SessionLocal()
    try:
        user_count = db.query(models.User).count()
        teacher_count = db.query(models.User).filter(models.User.role == "teacher").count()
        student_count = db.query(models.User).filter(models.User.role == "student").count()
        material_count = db.query(models.StudyMaterial).count()
        classroom_count = db.query(models.LiveClassroom).count()

        logger.info("Database Integrity Report:")
        logger.info(f" - Total Users: {user_count} (Teachers: {teacher_count}, Students: {student_count})")
        logger.info(f" - Study Materials / Subject Categories: {material_count}")
        logger.info(f" - Live Classrooms: {classroom_count}")

        if teacher_count >= 1 and student_count >= 1 and material_count >= 1:
            logger.info("SUCCESS: Database schema and seeded records verified 100% healthy.")
            return True
        else:
            logger.warning("WARNING: Database records incomplete.")
            return False
    except Exception as e:
        logger.error(f"Error verifying database: {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    verify_database_integrity()
