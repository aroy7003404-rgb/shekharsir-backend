import os
import sys
import logging

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "backend"))

try:
    from seed import seed_database
except ImportError:
    from backend.seed import seed_database

from verify_db import verify_database_integrity

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s]: %(message)s")
logger = logging.getLogger("seed_test")

def test_seed_idempotency():
    """Test running database seed twice consecutively to verify idempotency."""
    logger.info("--- Testing First Pass Database Seeding ---")
    seed_database()

    logger.info("--- Testing Second Pass Database Seeding (Idempotency Check) ---")
    try:
        seed_database()
        logger.info("SUCCESS: Second pass seeding completed cleanly without duplicate key errors.")
    except Exception as e:
        logger.error(f"FAILED: Duplicate key or constraint violation during second pass: {e}")
        sys.exit(1)

    verify_database_integrity()

if __name__ == "__main__":
    test_seed_idempotency()
