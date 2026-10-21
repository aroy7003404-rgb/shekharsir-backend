import os
import logging
from typing import Dict, Any

logger = logging.getLogger("shekharsir_api")

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://xyzcompany.supabase.co")
STORAGE_BUCKET = os.getenv("STORAGE_BUCKET", "materials")

class CloudStorageService:
    def __init__(self):
        self.bucket_name = STORAGE_BUCKET
        self.supabase_url = SUPABASE_URL

    def generate_presigned_upload_url(
        self,
        object_key: str,
        content_type: str = "application/pdf",
        expires_in: int = 3600
    ) -> Dict[str, Any]:
        """Generate a temporary pre-signed PUT upload URL for direct cloud storage."""
        upload_url = f"{self.supabase_url}/storage/v1/object/upload/sign/{self.bucket_name}/{object_key}?token=upload_ssc_{expires_in}"
        return {"upload_url": upload_url, "object_key": object_key, "expires_in": expires_in}

    def generate_presigned_download_url(
        self,
        object_key: str,
        expires_in: int = 3600
    ) -> Dict[str, Any]:
        """Generate a temporary pre-signed GET download/stream URL for secure file retrieval."""
        download_url = f"{self.supabase_url}/storage/v1/object/public/{self.bucket_name}/{object_key}"
        return {"download_url": download_url, "object_key": object_key, "expires_in": expires_in}

storage_service = CloudStorageService()
