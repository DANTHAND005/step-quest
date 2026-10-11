"""Shared test setup. Every test gets its own empty database."""

import pytest
from fastapi.testclient import TestClient

from stepquest import auth, db
from stepquest.main import app


@pytest.fixture(autouse=True)
def fresh_db(tmp_path, monkeypatch):
    monkeypatch.setenv("STEPQUEST_DB", str(tmp_path / "test.db"))
    auth._fails.clear()
    db.init_db()


@pytest.fixture
def conn():
    """A raw database connection, for testing logic functions directly."""
    c = db.connect()
    yield c
    c.close()


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture
def make_user(client):
    """make_user("dan") -> headers to call the API as dan."""
    def _make(username, password="password1"):
        r = client.post("/auth/signup", json={"username": username, "password": password})
        assert r.status_code == 200, r.text
        return {"Authorization": f"Bearer {r.json()['token']}"}
    return _make


def befriend(client, a_headers, b_headers, b_name):
    """a sends b a request, b accepts it."""
    client.post("/friends/request", json={"username": b_name}, headers=a_headers)
    request = client.get("/friends", headers=b_headers).json()["requests"][0]
    client.post(f"/friends/{request['id']}/accept", headers=b_headers)
