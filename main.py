import os
from datetime import datetime, timedelta
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from jose import JWTError, jwt
from dotenv import load_dotenv

import models
import schemas
from database import engine, get_db
from routers import tests as tests_router
from routers import materials as materials_router
from routers import attendance as attendance_router
from routers import classroom as classroom_router

load_dotenv()

# JWT Configurations
SECRET_KEY = os.getenv("SECRET_KEY", "your_super_secret_jwt_key_here")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = timedelta(days=7)  # Token valid for 7 days

# Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

app = FastAPI(
    title="Shekhar Sir Classes API",
    description="Backend API for Shekhar Sir Classes Educational Management System",
    version="1.0.0"
)

# Static Files Directory Setup
UPLOAD_DIR = os.path.join("uploads", "materials")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/static/materials", StaticFiles(directory=UPLOAD_DIR), name="materials")

# CORS Middleware (allows mobile and web clients to connect)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(tests_router.router)
app.include_router(materials_router.router)
app.include_router(attendance_router.router)
app.include_router(classroom_router.router)

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

@app.get("/")
def read_root():
    return {"message": "Welcome to Shekhar Sir Classes Backend API"}

# 1. User Signup Endpoint
@app.post("/api/signup", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def signup(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists."
        )

    # Hash password
    hashed_password = pwd_context.hash(user_data.password)

    # Create new user instance
    new_user = models.User(
        name=user_data.name,
        email=user_data.email,
        password_hash=hashed_password,
        role=user_data.role or "student"
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user

# 2. User Login Endpoint
@app.post("/api/login")
def login(login_data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == login_data.email).first()

    if not user or not user.password_hash or not pwd_context.verify(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": user.email, "role": user.role})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role,
        }
    }

# 3. Google Login / Auto-Registration Endpoint
@app.post("/api/google-login")
def google_login(google_data: schemas.GoogleLoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == google_data.email).first()

    if not user:
        # Auto-register new user via Google Sign-In
        user = models.User(
            name=google_data.name,
            email=google_data.email,
            password_hash=None,  # No password for Google auth users
            role=google_data.role or "student"
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token(data={"sub": user.email, "role": user.role})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role,
        }
    }