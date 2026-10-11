from datetime import date, timedelta

TODAY = date.today().isoformat()


def test_no_token_is_rejected(client):
    assert client.post("/steps", json={"days": [{"date": TODAY, "steps": 10}]}).status_code == 401


def test_bad_token_is_rejected(client):
    r = client.post("/steps", json={"days": []}, headers={"Authorization": "Bearer fake"})
    assert r.status_code == 401


def test_post_steps_returns_summary(client, make_user):
    h = make_user("dan")
    r = client.post("/steps", json={"days": [{"date": TODAY, "steps": 3500}]}, headers=h)
    assert r.json() == {"today": 3500, "week": 3500, "total": 3500, "coins": 30}


def test_same_day_twice_replaces(client, make_user):
    h = make_user("dan")
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 1000}]}, headers=h)
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 4000}]}, headers=h)
    assert client.get("/me", headers=h).json()["total"] == 4000


def test_rejects_out_of_range_steps(client, make_user):
    h = make_user("dan")
    for bad in (-1, 100_001):
        r = client.post("/steps", json={"days": [{"date": TODAY, "steps": bad}]}, headers=h)
        assert r.status_code == 422


def test_rejects_future_date(client, make_user):
    h = make_user("dan")
    future = (date.today() + timedelta(days=5)).isoformat()
    r = client.post("/steps", json={"days": [{"date": future, "steps": 10}]}, headers=h)
    assert r.status_code == 400


def test_rejects_more_than_31_days(client, make_user):
    h = make_user("dan")
    days = [{"date": (date.today() - timedelta(days=i)).isoformat(), "steps": 1} for i in range(32)]
    assert client.post("/steps", json={"days": days}, headers=h).status_code == 422


def test_bad_batch_saves_nothing(client, make_user):
    h = make_user("dan")
    future = (date.today() + timedelta(days=5)).isoformat()
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 500}, {"date": future, "steps": 1}]}, headers=h)
    assert client.get("/me", headers=h).json()["total"] == 0
