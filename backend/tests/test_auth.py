import pytest

def test_user_signup(client):
    payload = {
        "name": "Dr. Priya Verma",
        "email": "priya.verma@shekharsir.edu",
        "password": "securepassword123",
        "role": "teacher"
    }
    response = client.post("/api/signup", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == "priya.verma@shekharsir.edu"
    assert data["user"]["role"] == "teacher"

def test_user_login(client):
    # First sign up user
    signup_payload = {
        "name": "Aarav Student",
        "email": "aarav@shekharsir.edu",
        "password": "studentpassword123",
        "role": "student"
    }
    client.post("/api/signup", json=signup_payload)

    # Login request
    login_payload = {
        "email": "aarav@shekharsir.edu",
        "password": "studentpassword123",
        "role": "student"
    }
    response = client.post("/api/login", json=login_payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["name"] == "Aarav Student"

def test_token_refresh(client):
    signup_payload = {
        "name": "Refresh User",
        "email": "refresh@shekharsir.edu",
        "password": "password123",
        "role": "teacher"
    }
    res = client.post("/api/signup", json=signup_payload)
    refresh_token = res.json()["refresh_token"]

    refresh_res = client.post("/api/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_res.status_code == 200
    data = refresh_res.json()
    assert "access_token" in data
    assert "refresh_token" in data

def test_rbac_student_blocked_from_teacher_route(client):
    # Register student account
    signup_payload = {
        "name": "Student User",
        "email": "student.rbac@shekharsir.edu",
        "password": "password123",
        "role": "student"
    }
    res = client.post("/api/signup", json=signup_payload)
    token = res.json()["access_token"]

    # Student attempts teacher-only route POST /api/classroom/create
    headers = {"Authorization": f"Bearer {token}"}
    classroom_payload = {
        "title": "Physics: Quantum Mechanics",
        "target_batch": "Grade 12 Physics (Batch A)"
    }
    response = client.post("/api/classroom/create", json=classroom_payload, headers=headers)
    assert response.status_code == 403
    assert "Operation not permitted" in response.json()["detail"]
