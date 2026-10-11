"""Steps and coins."""

from datetime import date, timedelta

COINS_PER_1000_STEPS = 10


def coins(total_steps):
    return total_steps // 1000 * COINS_PER_1000_STEPS


def save_steps(db, user_id, day, steps):
    """Save a day's steps. Sending the same day again replaces it."""
    db.execute(
        """INSERT INTO step_days (user_id, date, steps) VALUES (?, ?, ?)
           ON CONFLICT (user_id, date) DO UPDATE SET steps = excluded.steps""",
        (user_id, day.isoformat(), steps),
    )


def date_range(name, today=None):
    """'today' or 'week' (last 7 days) -> (start, end) dates."""
    today = today or date.today()
    if name == "today":
        return today, today
    if name == "week":
        return today - timedelta(days=6), today
    raise ValueError("Range must be 'today' or 'week'")


def steps_between(db, user_id, start, end):
    row = db.execute(
        "SELECT COALESCE(SUM(steps), 0) FROM step_days WHERE user_id = ? AND date BETWEEN ? AND ?",
        (user_id, start.isoformat(), end.isoformat()),
    ).fetchone()
    return row[0]


def total_steps(db, user_id):
    return db.execute(
        "SELECT COALESCE(SUM(steps), 0) FROM step_days WHERE user_id = ?", (user_id,)
    ).fetchone()[0]


def summary(db, user_id, today=None):
    """Everything the home screen shows."""
    total = total_steps(db, user_id)
    return {
        "today": steps_between(db, user_id, *date_range("today", today)),
        "week": steps_between(db, user_id, *date_range("week", today)),
        "total": total,
        "coins": coins(total),
    }
