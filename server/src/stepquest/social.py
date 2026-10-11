"""Friends and the leaderboard."""

from .steps import date_range


def send_request(db, me, username):
    friend = db.execute("SELECT id FROM users WHERE username = ?", (username,)).fetchone()
    if not friend:
        raise ValueError("No user with that name")
    if friend["id"] == me:
        raise ValueError("You can't add yourself")

    existing = db.execute(
        "SELECT status FROM friends WHERE user_id = ? AND friend_id = ?", (me, friend["id"])
    ).fetchone()
    if existing:
        raise ValueError("Already friends" if existing["status"] == "accepted" else "Request already sent")

    # They already asked me? Then this counts as accepting.
    if is_pending(db, friend["id"], me):
        accept(db, me, friend["id"])
        return
    db.execute(
        "INSERT INTO friends (user_id, friend_id, status) VALUES (?, ?, 'pending')",
        (me, friend["id"]),
    )


def is_pending(db, from_id, to_id):
    return db.execute(
        "SELECT 1 FROM friends WHERE user_id = ? AND friend_id = ? AND status = 'pending'",
        (from_id, to_id),
    ).fetchone() is not None


def accept(db, me, from_id):
    if not is_pending(db, from_id, me):
        raise ValueError("No request from that user")
    db.execute(
        "UPDATE friends SET status = 'accepted' WHERE user_id = ? AND friend_id = ?",
        (from_id, me),
    )
    db.execute(
        "INSERT INTO friends (user_id, friend_id, status) VALUES (?, ?, 'accepted')",
        (me, from_id),
    )


def friends(db, me):
    rows = db.execute(
        """SELECT u.id, u.username FROM friends f JOIN users u ON u.id = f.friend_id
           WHERE f.user_id = ? AND f.status = 'accepted' ORDER BY u.username""",
        (me,),
    )
    return [dict(r) for r in rows]


def incoming_requests(db, me):
    rows = db.execute(
        """SELECT u.id, u.username FROM friends f JOIN users u ON u.id = f.user_id
           WHERE f.friend_id = ? AND f.status = 'pending' ORDER BY u.username""",
        (me,),
    )
    return [dict(r) for r in rows]


def leaderboard(db, me, range_name="week", today=None):
    """Me and my friends, most steps first."""
    start, end = date_range(range_name, today)
    rows = db.execute(
        """SELECT u.username, COALESCE(SUM(s.steps), 0) AS steps
           FROM users u
           LEFT JOIN step_days s ON s.user_id = u.id AND s.date BETWEEN ? AND ?
           WHERE u.id = ?
              OR u.id IN (SELECT friend_id FROM friends WHERE user_id = ? AND status = 'accepted')
           GROUP BY u.id
           ORDER BY steps DESC, u.username""",
        (start.isoformat(), end.isoformat(), me, me),
    )
    return [dict(r) for r in rows]
