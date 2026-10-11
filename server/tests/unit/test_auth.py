import pytest

from stepquest import auth


def test_password_hash_roundtrip():
    stored = auth.hash_password("password1")
    assert "password1" not in stored
    assert auth.verify_password("password1", stored)
    assert not auth.verify_password("wrong", stored)


def test_same_password_hashes_differently():
    assert auth.hash_password("password1") != auth.hash_password("password1")


@pytest.mark.parametrize("username", ["ab", "a" * 21, "bad name", "bad-name"])
def test_bad_usernames(conn, username):
    with pytest.raises(ValueError):
        auth.signup(conn, username, "password1")


def test_short_password(conn):
    with pytest.raises(ValueError):
        auth.signup(conn, "dan", "short")


def test_duplicate_username(conn):
    auth.signup(conn, "dan", "password1")
    with pytest.raises(ValueError, match="taken"):
        auth.signup(conn, "dan", "password2")


def test_login_returns_same_token_as_signup(conn):
    token = auth.signup(conn, "dan", "password1")
    assert auth.login(conn, "dan", "password1") == token


def test_wrong_password_and_unknown_user_look_the_same(conn):
    auth.signup(conn, "dan", "password1")
    with pytest.raises(ValueError) as wrong_pw:
        auth.login(conn, "dan", "nope")
    with pytest.raises(ValueError) as no_user:
        auth.login(conn, "ghost", "nope")
    assert str(wrong_pw.value) == str(no_user.value)


def test_locks_after_5_fails(conn):
    auth.signup(conn, "dan", "password1")
    for _ in range(5):
        with pytest.raises(ValueError):
            auth.login(conn, "dan", "nope")
    with pytest.raises(ValueError, match="Too many"):
        auth.login(conn, "dan", "password1")  # right password, still locked
