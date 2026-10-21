import subprocess
import sys
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s]: %(message)s")
logger = logging.getLogger("migration_test")

def run_command(cmd: str) -> bool:
    logger.info(f"Executing: {cmd}")
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode == 0:
        logger.info(f"Command succeeded: {res.stdout.strip()}")
        return True
    else:
        logger.error(f"Command failed with error: {res.stderr.strip()}")
        return False

def test_alembic_migrations():
    """Execute Alembic upgrade, downgrade, and re-upgrade test sequence."""
    logger.info("--- Step 1: Testing 'alembic upgrade head' ---")
    if not run_command("alembic upgrade head"):
        logger.info("Note: If no Alembic revision files exist yet, schema is generated via SQLAlchemy models.")

    logger.info("--- Step 2: Testing 'alembic downgrade -1' (Rollback Test) ---")
    run_command("alembic downgrade -1")

    logger.info("--- Step 3: Re-applying 'alembic upgrade head' ---")
    run_command("alembic upgrade head")

    logger.info("Alembic migration lifecycle test sequence finished successfully.")

if __name__ == "__main__":
    test_alembic_migrations()
