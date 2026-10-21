from database import engine, Base
import models

def init_db():
    print("Initializing database tables in PostgreSQL...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

if __name__ == "__main__":
    init_db()
