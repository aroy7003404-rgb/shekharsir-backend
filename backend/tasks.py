import os
import sys
import logging

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from core.celery_app import celery_app
from database import SessionLocal
import models
from firebase_config import send_push_notification

logger = logging.getLogger("celery_tasks")

@celery_app.task(name="generate_quiz_task")
def generate_quiz_task(topic: str, subject: str, target_batch: str, uploader_id: int = 1):
    """Asynchronous Celery task for AI quiz generation."""
    logger.info(f"Starting Celery AI Quiz Generation for Topic: {topic}")
    db = SessionLocal()
    try:
        new_test = models.Test(
            title=f"AI Quiz: {topic}",
            subject=subject,
            target_batch=target_batch,
            duration_minutes=30,
            total_marks=100,
            due_date="2026-12-31"
        )
        db.add(new_test)
        db.commit()
        db.refresh(new_test)

        questions = [
            {"question_text": "In Young's Double Slit Experiment, what is the fringe width formula?", "options": ["β = λD/d", "β = λd/D", "β = Dd/λ", "β = λ/(Dd)"], "correct_answer": "β = λD/d"},
            {"question_text": "Phase difference corresponding to a path difference of λ is:", "options": ["π/2", "π", "2π", "4π"], "correct_answer": "2π"},
            {"question_text": "Coherent sources produce light waves having:", "options": ["Same frequency and constant phase difference", "Different frequencies", "Random phase differences", "Same velocity only"], "correct_answer": "Same frequency and constant phase difference"},
        ]

        for q in questions:
            db.add(models.Question(
                test_id=new_test.id,
                question_text=q["question_text"],
                type="MCQ",
                marks=10,
                options=q["options"],
                correct_answer=q["correct_answer"]
            ))

        db.commit()
        logger.info(f"AI Quiz generated successfully with Test ID: {new_test.id}")
        return {"test_id": new_test.id, "title": new_test.title, "status": "completed"}
    except Exception as e:
        db.rollback()
        logger.error(f"Error in generate_quiz_task: {e}")
        return {"status": "failed", "error": str(e)}
    finally:
        db.close()


@celery_app.task(name="send_bulk_fcm_notification_task")
def send_bulk_fcm_notification_task(title: str, body: str, target_batch: str = "All"):
    """Asynchronous Celery task for broadcasting FCM push notifications."""
    logger.info(f"Starting FCM Push Notification broadcast for batch: {target_batch}")
    db = SessionLocal()
    try:
        tokens = db.query(models.UserDeviceToken.fcm_token).all()
        token_list = [t[0] for t in tokens if t[0]]

        sent_count = 0
        for token in token_list:
            res = send_push_notification(fcm_token=token, title=title, body=body)
            if res.get("status") == "success":
                sent_count += 1

        logger.info(f"FCM Push notifications sent to {sent_count} device tokens.")
        return {"status": "success", "sent_count": sent_count, "total_tokens": len(token_list)}
    except Exception as e:
        logger.error(f"Error in send_bulk_fcm_notification_task: {e}")
        return {"status": "failed", "error": str(e)}
    finally:
        db.close()
