import os
import logging
from typing import Dict, Any, Optional

logger = logging.getLogger("shekharsir_fcm")

try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    # Initialize Firebase Admin SDK if service account JSON exists
    cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "firebase_service_account.json")
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        FIREBASE_INITIALIZED = True
        logger.info("Firebase Admin SDK initialized successfully.")
    else:
        FIREBASE_INITIALIZED = False
        logger.warning("Firebase service account JSON not found. Running FCM in mock/simulation mode.")
except Exception as e:
    FIREBASE_INITIALIZED = False
    logger.warning(f"Firebase Admin SDK initialization skipped: {e}")


def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> bool:
    """Send targeted Firebase Cloud Messaging push notification to device token."""
    if not fcm_token:
        return False

    if FIREBASE_INITIALIZED:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=fcm_token,
            )
            response = messaging.send(message)
            logger.info(f"FCM push notification sent successfully: {response}")
            return True
        except Exception as e:
            logger.error(f"Failed to send FCM push notification: {e}")
            return False
    else:
        logger.info(f"[SIMULATED FCM PUSH] Token: {fcm_token} | Title: {title} | Body: {body}")
        return True
