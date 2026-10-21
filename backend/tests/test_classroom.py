import pytest

def test_create_and_fetch_classroom(client):
    # Register teacher account
    signup_payload = {
        "name": "Prof. Shekhar Sir",
        "email": "shekhar.sir@shekharsir.edu",
        "password": "teacherpassword123",
        "role": "teacher"
    }
    res = client.post("/api/signup", json=signup_payload)
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create classroom
    classroom_payload = {
        "title": "Physics: Wave Optics Interference",
        "target_batch": "Grade 12 Physics (Batch A)"
    }
    create_res = client.post("/api/classroom/create", json=classroom_payload, headers=headers)
    assert create_res.status_code == 201
    room_data = create_res.json()
    assert room_data["title"] == "Physics: Wave Optics Interference"
    assert "room_token" in room_data

    # Fetch active classrooms list
    list_res = client.get("/api/classroom/active/All")
    assert list_res.status_code == 200
    rooms = list_res.json()
    assert len(rooms) >= 1

def test_upload_and_fetch_classroom_recordings(client):
    # Register teacher
    res = client.post("/api/signup", json={
        "name": "Teacher Upload",
        "email": "teacher.upload@shekharsir.edu",
        "password": "password123",
        "role": "teacher"
    })
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create room
    room_res = client.post("/api/classroom/create", json={
        "title": "Chemistry: Organic Reactions",
        "target_batch": "Grade 12 Chemistry"
    }, headers=headers)
    classroom_id = room_res.json()["id"]

    # Upload recording
    upload_res = client.post(
        f"/api/classroom/{classroom_id}/materials/upload",
        data={
            "title": "Recorded Lecture: Organic Reactions",
            "description": "Recorded live classroom session",
            "file_type": "Video",
            "file_url": "https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4"
        },
        headers=headers
    )
    assert upload_res.status_code == 201
    rec_data = upload_res.json()
    assert rec_data["classroom_id"] == classroom_id

    # Fetch classroom recordings
    fetch_res = client.get(f"/api/classroom/{classroom_id}/materials")
    assert fetch_res.status_code == 200
    recordings = fetch_res.json()
    assert len(recordings) >= 1
    assert recordings[0]["title"] == "Recorded Lecture: Organic Reactions"
