# Step Quest

Walk, earn coins, beat your friends.
Every 1000 steps = 10 coins. Add friends and compete on a daily or weekly leaderboard.

```
iPhone Shortcut ──POST /steps──▶  Python server (FastAPI + SQLite)  ◀──── Flutter app
reads Apple Health                server/                                 app/
```

## Folders

| Folder | What's in it |
|---|---|
| `server/` | The Python API. All game logic and tests live here. |
| `app/` | The Flutter app: log in, today's steps and coins, leaderboard, friends, profile. |
| `shortcut/` | How to build the iPhone Shortcut that sends your steps. |
| `docs/` | The user manual, the architecture doc, and the Sprint 1 retrospective (Marp slides). |

## Run the server

Needs [uv](https://docs.astral.sh/uv/).

```bash
cd server
uv sync
uv run uvicorn stepquest.main:app --reload --host 0.0.0.0
```

Open http://localhost:8000/docs to try every route in the browser.

Run the tests:

```bash
cd server
uv run pytest
```

## Run the app

Start the server first (above). Then in a second terminal:

```bash
cd app
flutter create --project-name step_quest --platforms=web,windows,android .   # first time only
flutter pub get
flutter run -d chrome
```

`flutter create .` only adds the platform folders. It never overwrites the files already in `lib/`.

Other targets: `flutter run -d windows` (needs Visual Studio with "Desktop development with C++"),
or start an Android emulator and run `flutter run`. The app picks the right server address for each.

Run the app tests: `flutter test`

## How the app is organized

```
app/lib/
  main.dart                 starts the app, theme, picks login or home
  api.dart                  every server call + saved login (one method per route)
  widgets.dart              LoadView (loading/error/pull-to-refresh), Avatar, formatNumber
  screens/
    login_screen.dart       log in / create account
    home_screen.dart        bottom navigation bar, list of tabs
    today_tab.dart          steps today, last 7 days, coins, progress to next coins
    leaderboard_tab.dart    you + friends ranked, today or last 7 days
    friends_tab.dart        add by username, accept requests, friend list
    profile_tab.dart        token for the iPhone Shortcut, log out
```

Adding a screen: add a method to `api.dart` for its route, make a `*_tab.dart` that wraps its content in
`LoadView`, and add one line to the `tabs` list in `home_screen.dart`.

## How the server is organized

```
server/src/stepquest/
  main.py      creates the app, turns ValueError into a 400 response
  schema.sql   every table
  db.py        opens the database
  auth.py      sign up, log in, tokens
  steps.py     saving steps, coins
  social.py    friends, leaderboard
  api.py       every route (thin: read request -> call a function -> return)
```

Rules that keep it simple:

1. **Logic files never touch HTTP.** `auth`, `steps`, `social` take a database connection and plain values. That makes them easy to test.
2. **Routes never hold logic.** `api.py` only reads the request and calls a logic function.
3. **Bad input = `raise ValueError("message")`.** The user gets a 400 with that message. Nothing else to set up.
4. **All SQL uses `?` placeholders.** Never put values into SQL with f-strings.

## Adding a feature

Example: a daily streak.

1. **Data?** Add a table to `schema.sql` if needed (a streak can be computed from `step_days`, so none here).
2. **Logic.** Add `def streak(db, user_id)` to `steps.py`, or a new file like `streaks.py` if it's a big feature.
3. **Route.** Add `@router.get("/streak")` to `api.py` that calls it.
4. **Tests.** A unit test for the logic, an integration test for the route.
5. Run `uv run pytest`.

## API

All routes except signup and login need `Authorization: Bearer <token>`.

| Method | Route | Body / query | Returns |
|---|---|---|---|
| POST | `/auth/signup` | `{username, password}` | `{token}` |
| POST | `/auth/login` | `{username, password}` | `{token}` |
| GET | `/me` | | `{username, today, week, total, coins}` |
| POST | `/steps` | `{"days": [{"date": "2026-10-10", "steps": 8423}]}` | same as `/me` minus username |
| POST | `/steps/today` | `{"steps": 8423}` | `{today, coins}` |
| GET | `/friends` | | `{friends: [...], requests: [...]}` |
| POST | `/friends/request` | `{username}` | `{ok}` |
| POST | `/friends/{id}/accept` | | `{ok}` |
| GET | `/leaderboard` | `?range=today` or `?range=week` | `[{username, steps}]` |

## Security

- Passwords hashed with scrypt. Login locks a username for 15 min after 5 wrong tries, and the error never says whether the username exists.
- Users are always found from their token, never from the request body.
- Steps must be 0-100,000 per day, not in the future, max 31 days per upload. A bad upload saves nothing.

**Known limit:** steps are sent by the user's phone, so someone could send fake numbers with their own token. The daily cap limits the damage. Fine for a game between friends.

## Tests

| Type | Folder | Covers |
|---|---|---|
| Unit | `tests/unit/` | coins math, date ranges, passwords, signup rules, login lockout |
| Integration | `tests/integration/` | every route through the real API and a real (temporary) database |
| Regression | `tests/regression/` | one test per fixed bug |
| Acceptance | `tests/acceptance/` | user stories start to finish |

Every test gets its own empty database, so tests never touch real data.
