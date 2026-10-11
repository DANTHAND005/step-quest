"""One test per bug that was fixed, so it never comes back.

How to add one:
    def test_<short_bug_name>(client, make_user):
        # Bug: what went wrong, and the date it was fixed.
        ...steps that used to break...
"""

from datetime import date, timedelta


def test_steps_outside_week_not_counted_in_week(client, make_user):
    # Guards the 7-day window edge: day 7 back is out, day 6 back is in.
    h = make_user("dan")
    today = date.today()
    client.post("/steps", json={"days": [
        {"date": (today - timedelta(days=7)).isoformat(), "steps": 5000},
        {"date": (today - timedelta(days=6)).isoformat(), "steps": 1000},
    ]}, headers=h)
    me = client.get("/me", headers=h).json()
    assert me["week"] == 1000
    assert me["total"] == 6000
