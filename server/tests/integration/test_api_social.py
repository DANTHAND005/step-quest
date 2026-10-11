from datetime import date

from conftest import befriend

TODAY = date.today().isoformat()


def names(rows):
    return [r["username"] for r in rows]


def test_request_then_accept(client, make_user):
    dan, sam = make_user("dan"), make_user("sam")
    client.post("/friends/request", json={"username": "sam"}, headers=dan)

    sam_view = client.get("/friends", headers=sam).json()
    assert names(sam_view["requests"]) == ["dan"]
    assert sam_view["friends"] == []

    client.post(f"/friends/{sam_view['requests'][0]['id']}/accept", headers=sam)
    assert names(client.get("/friends", headers=dan).json()["friends"]) == ["sam"]
    assert names(client.get("/friends", headers=sam).json()["friends"]) == ["dan"]
    assert client.get("/friends", headers=sam).json()["requests"] == []


def test_both_sending_requests_makes_friends(client, make_user):
    dan, sam = make_user("dan"), make_user("sam")
    client.post("/friends/request", json={"username": "sam"}, headers=dan)
    client.post("/friends/request", json={"username": "dan"}, headers=sam)
    assert names(client.get("/friends", headers=dan).json()["friends"]) == ["sam"]


def test_request_errors(client, make_user):
    dan = make_user("dan")
    make_user("sam")
    assert client.post("/friends/request", json={"username": "ghost"}, headers=dan).status_code == 400
    assert client.post("/friends/request", json={"username": "dan"}, headers=dan).status_code == 400
    client.post("/friends/request", json={"username": "sam"}, headers=dan)
    assert client.post("/friends/request", json={"username": "sam"}, headers=dan).status_code == 400


def test_cannot_accept_without_request(client, make_user):
    dan = make_user("dan")
    make_user("sam")
    assert client.post("/friends/2/accept", headers=dan).status_code == 400


def test_leaderboard_has_me_and_friends_only(client, make_user):
    dan, sam, amy = make_user("dan"), make_user("sam"), make_user("amy")
    befriend(client, dan, sam, "sam")
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 2000}]}, headers=dan)
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 9000}]}, headers=sam)
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 50000}]}, headers=amy)  # not a friend

    board = client.get("/leaderboard?range=today", headers=dan).json()
    assert board == [{"username": "sam", "steps": 9000}, {"username": "dan", "steps": 2000}]


def test_pending_friend_not_on_leaderboard(client, make_user):
    dan = make_user("dan")
    make_user("sam")
    client.post("/friends/request", json={"username": "sam"}, headers=dan)
    assert names(client.get("/leaderboard", headers=dan).json()) == ["dan"]


def test_leaderboard_bad_range(client, make_user):
    assert client.get("/leaderboard?range=year", headers=make_user("dan")).status_code == 400
