"""User stories, written the way a user would use the app."""

from datetime import date

TODAY = date.today().isoformat()


def test_walk_and_earn_coins(client):
    # As a user, I sign up, my phone syncs steps, and I see my coins.
    token = client.post("/auth/signup", json={"username": "dan", "password": "password1"}).json()["token"]
    phone = {"Authorization": f"Bearer {token}"}

    client.post("/steps", json={"days": [{"date": TODAY, "steps": 3000}]}, headers=phone)

    me = client.get("/me", headers=phone).json()
    assert me["username"] == "dan"
    assert me["today"] == 3000
    assert me["coins"] == 30


def test_compete_with_a_friend(client):
    # As a user, I add a friend and we both show up on the leaderboard.
    def join(name):
        token = client.post("/auth/signup", json={"username": name, "password": "password1"}).json()["token"]
        return {"Authorization": f"Bearer {token}"}

    dan, sam = join("dan"), join("sam")
    client.post("/friends/request", json={"username": "sam"}, headers=dan)
    request_id = client.get("/friends", headers=sam).json()["requests"][0]["id"]
    client.post(f"/friends/{request_id}/accept", headers=sam)

    client.post("/steps", json={"days": [{"date": TODAY, "steps": 4000}]}, headers=dan)
    client.post("/steps", json={"days": [{"date": TODAY, "steps": 6000}]}, headers=sam)

    for viewer in (dan, sam):
        board = client.get("/leaderboard", headers=viewer).json()
        assert [row["username"] for row in board] == ["sam", "dan"]


def test_log_back_in_on_new_device(client):
    # As a user, logging in again gives the same token my Shortcut uses.
    signup_token = client.post("/auth/signup", json={"username": "dan", "password": "password1"}).json()["token"]
    login_token = client.post("/auth/login", json={"username": "dan", "password": "password1"}).json()["token"]
    assert login_token == signup_token
