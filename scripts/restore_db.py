import os
import sys
import gzip
import subprocess
import logging

logger = logging.getLogger("db_restore")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s]: %(message)s")

TARGET_DATABASE_URL = os.getenv(
    "TARGET_DATABASE_URL",
    os.getenv("DATABASE_URL", "postgresql+psycopg2://postgres:postgrespassword@localhost:5432/shekharsir_db")
)
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME", "shekharsir-backups")
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL", "https://s3.amazonaws.com")
AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")

def clean_db_url(url: str) -> str:
    if "+psycopg2" in url:
        return url.replace("+psycopg2", "")
    return url

def download_backup_from_s3(object_key: str, local_path: str = "restore_backup.sql.gz"):
    """Download backup archive from S3 bucket."""
    logger.info(f"Downloading backup '{object_key}' from S3 bucket '{S3_BUCKET_NAME}'...")
    try:
        import boto3
        s3 = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            endpoint_url=S3_ENDPOINT_URL,
            region_name=AWS_REGION
        )
        s3.download_file(S3_BUCKET_NAME, object_key, local_path)
        logger.info(f"Backup downloaded successfully to {local_path}")
        return local_path
    except Exception as e:
        logger.error(f"Failed to download backup from S3: {e}")
        return None

def restore_database(compressed_path: str):
    """Decompress archive and restore PostgreSQL database via psql."""
    logger.info(f"Restoring database from {compressed_path}...")
    uncompressed_sql = "restore_temp.sql"
    pg_url = clean_db_url(TARGET_DATABASE_URL)

    try:
        with gzip.open(compressed_path, "rb") as gz_in:
            with open(uncompressed_sql, "wb") as sql_out:
                sql_out.write(gz_in.read())

        cmd = f"psql {pg_url} -f {uncompressed_sql}"
        proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)

        if proc.returncode == 0:
            logger.info("Database restored successfully via psql.")
        else:
            logger.error(f"psql restore error: {proc.stderr}")

    except Exception as e:
        logger.error(f"Error during database restore: {e}")
    finally:
        if os.path.exists(uncompressed_sql):
            os.remove(uncompressed_sql)
        if os.path.exists(compressed_path):
            os.remove(compressed_path)

def main():
    if len(sys.argv) < 2:
        logger.info("Usage: python restore_db.py <S3_OBJECT_KEY_OR_LOCAL_FILE>")
        logger.info("Example: python restore_db.py db_backups/backup_2026-10-24_00-00-00.sql.gz")
        sys.exit(1)

    source = sys.argv[1]
    if source.endswith(".sql.gz") and os.path.exists(source):
        restore_database(source)
    else:
        local_file = download_backup_from_s3(source)
        if local_file:
            restore_database(local_file)

if __name__ == "__main__":
    main()
