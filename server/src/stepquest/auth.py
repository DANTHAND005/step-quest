"""Accounts: sign up, log in, and finding a user from their token."""

import hashlib
import hmac
import re
import secrets
import time

USERNAME_RULE = re.compile(r"^[A-Za-z0-9_]{3,20}$")
MIN_PASSWORD = 8
MAX_FAILS = 5
LOCK_SECONDS = 15 * 60

# username -> (failed attempts, locked until)
# ponytail: in memory, resets when the server restarts. Fine for one server.
_fails = {}


def hash_password(password):
    salt = secrets.token_bytes(16)
    digest = hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1)
    return f"{salt.hex()}${digest.hex()}"


def verify_password(password, stored):
    salt_hex, digest_hex = stored.split("$")
    digest = hashlib.scrypt(password.encode(), salt=bytes.fromhex(salt_hex), n=2**14, r=8, p=1)
    return hmac.compare_digest(digest.hex(), digest_hex)


def new_token():
    return secrets.token_urlsafe(32)


def signup(db, username, password):
    """Create an account and return its token."""
    if not USERNAME_RULE.match(username):
        raise ValueError("Username must be 3-20 letters, numbers, or _")
    if len(password) < MIN_PASSWORD:
        raise ValueError(f"Password must be at least {MIN_PASSWORD} characters")
    if db.execute("SELECT 1 FROM users WHERE username = ?", (username,)).fetchone():
        raise ValueError("Username is taken")
    token = new_token()
    db.execute(
        "INSERT INTO users (username, pw_hash, api_token) VALUES (?, ?, ?)",
        (username, hash_password(password), token),
    )
    return token


def login(db, username, password):
    """Return the user's token. Locks the username after too many wrong passwords."""
    count, locked_until = _fails.get(username, (0, 0))
    if time.monotonic() < locked_until:
        raise ValueError("Too many attempts. Try again in 15 minutes")

    user = db.execute(
        "SELECT pw_hash, api_token FROM users WHERE username = ?", (username,)
    ).fetchone()
    if user and verify_password(password, user["pw_hash"]):
        _fails.pop(username, None)
        return user["api_token"]

    count += 1
    _fails[username] = (count, time.monotonic() + LOCK_SECONDS if count >= MAX_FAILS else 0)
    # Same message either way, so nobody can test which usernames exist.
    raise ValueError("Wrong username or password")


def user_from_token(db, token):
    """Return the user row for a token, or None."""
    return db.execute(
        "SELECT id, username FROM users WHERE api_token = ?", (token,)
    ).fetchone()
