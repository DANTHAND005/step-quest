---
marp: true
paginate: true
title: Step Quest Architecture
---

# Step Quest: Architecture

ASE420 Individual Project · Daniel Than

Walk, earn coins, compete with friends.
Every 1,000 steps = 10 coins.

---

## Goal

- Count steps automatically from Apple Health. No manual entry.
- Turn steps into coins.
- Add friends and compete on a daily and weekly leaderboard.
- Keep the code simple enough that anyone can add a feature.

---

## System overview

```
 iPhone                         PC                              PC / phone
┌────────────────┐   HTTP    ┌──────────────────────┐   HTTP   ┌──────────────┐
│ iOS Shortcut   │ ───────▶  │ Python server        │ ◀──────  │ Flutter app  │
│ reads Apple    │ POST      │ FastAPI + SQLite     │  JSON    │ Today, Board │
│ Health steps   │ /steps/   │ stepquest.db         │          │ Friends,     │
│ 3x a day       │ today     │                      │          │ Profile      │
└────────────────┘           └──────────────────────┘          └──────────────┘
         └──────── Tailscale private network ────────┘
```

The server is the single source of truth. The phone only sends steps. The app only reads and shows data.

---

## Tech stack

| Part | Choice | Why |
|---|---|---|
| Server | Python 3.13, FastAPI, uvicorn | Required Python, small and fast to build |
| Database | SQLite, built into Python | One file, no setup |
| Packages | uv | Course standard, locked versions |
| App | Flutter, Dart | Same code runs in Chrome, Windows, Android |
| Steps | iOS Shortcuts + Apple Health | Only free way to read Health data without a Mac |
| Network | Tailscale | Phone reaches the PC securely from anywhere |
| Tests | pytest, flutter_test | Unit, integration, regression, acceptance |

---

## Server layout

```
server/src/stepquest/
  main.py      creates the app, turns ValueError into a 400 response
  schema.sql   every table
  db.py        opens the database, one connection per request
  auth.py      sign up, log in, password hashing, tokens
  steps.py     saving steps, totals, coins
  social.py    friend requests, friend list, leaderboard
  api.py       every route
```

Rules:
1. Logic files never touch HTTP. They take a database connection and plain values.
2. Routes never hold logic. They read the request, call one function, return the result.
3. Bad input means `raise ValueError("message")`. The user gets a 400 with that message.
4. All SQL uses `?` placeholders.

---

## Data model

```sql
users      id, username, pw_hash, api_token
step_days  user_id, date, steps            PRIMARY KEY (user_id, date)
friends    user_id, friend_id, status      'pending' or 'accepted'
```

- One row per user per day. Syncing the same day again replaces the number, so extra syncs are harmless.
- Coins are not stored. They are calculated from total steps: `total // 1000 * 10`. They can never get out of sync.
- Accepting a friend request adds a row in both directions, so "my friends" is one simple query.

---

## API

| Method | Route | Used by |
|---|---|---|
| POST | `/auth/signup`, `/auth/login` | App |
| GET | `/me` | App: steps today, week, total, coins |
| POST | `/steps/today` | iPhone Shortcut: `{"steps": 8423}` |
| POST | `/steps` | Backfill up to 31 days at once |
| GET | `/friends` | App: friends + incoming requests |
| POST | `/friends/request`, `/friends/{id}/accept` | App |
| GET | `/leaderboard?range=today` or `week` | App |

Every route except signup and login needs `Authorization: Bearer <token>`.

---

## How a step sync works

1. A Shortcut automation runs at noon, 6 PM and 11:55 PM.
2. It asks Apple Health for today's steps, grouped by day so iPhone and Apple Watch are not double counted.
3. It sends `POST /steps/today` with the user's token.
4. The server finds the user from the token, saves today's row, and replies with steps and coins.
5. Next time the app loads, it shows the new numbers.

---

## App layout

```
app/lib/
  main.dart              starts the app, picks login or home
  api.dart               every server call in one place
  widgets.dart           LoadView: loading, error + retry, pull to refresh
  screens/
    login_screen.dart    log in or create account
    home_screen.dart     bottom navigation, list of tabs
    today_tab.dart       steps, last 7 days, coins, progress bar
    leaderboard_tab.dart today / last 7 days rankings
    friends_tab.dart     add by username, accept requests
    profile_tab.dart     token, log out
```

Adding a screen: one method in `api.dart`, one tab file, one line in `home_screen.dart`.

---

## Key design decisions

| Decision | Reason | Trade-off |
|---|---|---|
| Steps come from an iOS Shortcut | Building an iPhone app needs a Mac or $99/year | Users set up the Shortcut once |
| App runs in Chrome / Windows | No Mac, no App Store | Friends can't install it on iPhone yet |
| SQLite | Zero setup | One server only |
| One token per user | Same token works for app and Shortcut | Changing it means updating the Shortcut |
| Coins calculated, not stored | Can't drift from steps | Spending coins will need a table later |

---

## Security

- Passwords hashed with scrypt and a random salt.
- Login locks a username for 15 minutes after 5 wrong tries. The error never says if the username exists.
- The user always comes from the token, never from the request body.
- Steps must be 0 to 100,000 per day and not in the future. A bad upload saves nothing.
- Only localhost pages can call the API from a browser.
- The server is only reachable over the private Tailscale network.

**Known limit:** steps come from the user's phone, so someone could send fake numbers with their own token. The daily cap limits this. It's fine for a game between friends.

---

## Testing

| Type | Where | What it checks |
|---|---|---|
| Unit | `server/tests/unit` | coins math, date ranges, password hashing, signup rules, lockout |
| Integration | `server/tests/integration` | every route through the real API and a temporary database |
| Regression | `server/tests/regression` | one test per fixed bug |
| Acceptance | `server/tests/acceptance` | user stories start to finish |
| App | `app/test` | number formatting, login form validation |

42 server tests. Each test gets its own empty database.

---

## Next: Sprint 2

- Loot crates with rarity tiers: common to mythic
- Spend coins on crates, so coins get a ledger table
- Item collection screen
- Deploy the server so friends don't depend on my PC
- Backfill missed days automatically
