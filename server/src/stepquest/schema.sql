-- Step Quest database. Runs on every startup; IF NOT EXISTS makes that safe.
-- New feature that needs data? Add a CREATE TABLE here.

CREATE TABLE IF NOT EXISTS users (
    id        INTEGER PRIMARY KEY,
    username  TEXT UNIQUE NOT NULL,
    pw_hash   TEXT NOT NULL,
    api_token TEXT UNIQUE NOT NULL
);

-- One row per user per day. Re-syncing a day overwrites it.
CREATE TABLE IF NOT EXISTS step_days (
    user_id INTEGER NOT NULL REFERENCES users(id),
    date    TEXT NOT NULL,  -- YYYY-MM-DD
    steps   INTEGER NOT NULL CHECK (steps BETWEEN 0 AND 100000),
    PRIMARY KEY (user_id, date)
);

-- A request is one 'pending' row (user_id -> friend_id).
-- Accepting turns it 'accepted' and adds the reverse row, so
-- "my friends" is always: WHERE user_id = me AND status = 'accepted'.
CREATE TABLE IF NOT EXISTS friends (
    user_id   INTEGER NOT NULL REFERENCES users(id),
    friend_id INTEGER NOT NULL REFERENCES users(id),
    status    TEXT NOT NULL CHECK (status IN ('pending', 'accepted')),
    PRIMARY KEY (user_id, friend_id)
);
