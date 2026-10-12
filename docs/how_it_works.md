---
marp: true
paginate: true
title: How Step Quest Works
style: |
  section { font-size: 28px; }
  table { font-size: 22px; }
---

# How Step Quest Works

From an iPhone step count to coins on a leaderboard

ASE420 Individual Project · Daniel Than

---

# Three parts, one flow

1. **iPhone Shortcut**: reads today's steps from Apple Health and sends the number to the server.
2. **Python server**: checks your token, saves the steps, and works out the coins. It runs on port 8000.
3. **Flutter app**: the Today, Leaderboard, Friends, and Profile screens. It asks the server for everything it shows.

The server's `/docs` page lists every route and lets you try each one.

---

# The Shortcut reads steps and sends them

1. Find Health Samples: Type is Steps, Start Date is today, Group by Day.
2. Calculate the Sum of those samples. That is today's step count.
3. Get contents of the server URL, which ends in `/steps/today`. The method is POST.
4. The request carries the token in an `Authorization` header, and the body is `{"steps": Sum}`.
5. Show the server's reply.

---

# The server answers with your totals

Example reply:

```
{"week": 148, "today": 148, "coins": 0, "total": ...}
```

- `today`: steps for today
- `week`: steps in the last 7 days
- `total`: all steps ever sent
- `coins`: total divided by 1,000, rounded down, times 10

---

# Every route the server has

| Method | Route | What it does | Login |
|---|---|---|---|
| POST | `/auth/signup` | Create an account and get a token | No |
| POST | `/auth/login` | Log in and get a token | No |
| GET | `/me` | Your username, steps, and coins | Yes |
| POST | `/steps` | Save steps for up to 31 days | Yes |
| POST | `/steps/today` | Save today's steps (the Shortcut uses this) | Yes |
| GET | `/friends` | Your friends and requests sent to you | Yes |
| POST | `/friends/request` | Ask someone to be your friend | Yes |
| POST | `/friends/{id}/accept` | Accept a friend request | Yes |
| GET | `/leaderboard` | You and your friends, most steps first | Yes |

"Login" means the route needs the token. The padlock icons on `/docs` mark them.

---

# Signup, login, and the token

**POST /auth/signup**: send `{username, password}`. The username is 3 to 20 letters, numbers, or `_`. The password is at least 8 characters. The reply is `{token}`.

**POST /auth/login**: send `{username, password}`. Five wrong passwords lock the username for 15 minutes. The reply is `{token}`.

The token proves who you are, and every other route needs it. In `/docs`, click Authorize and paste only the token. The page adds `Bearer` for you.

---

# POST /steps/today and POST /steps

**POST /steps/today**: body `{"steps": 8423}`. One number for today. The server uses its own date, and sending again replaces the earlier number.

**POST /steps**: body `{"days": [{"date": "2026-10-10", "steps": 8423}]}`. Up to 31 days at once. Dates in the future are rejected.

Both accept 0 to 100,000 steps per day.

---

# Steps become coins

**coins = total steps ÷ 1,000, rounded down, × 10**

Example: 8,423 steps is 8 full thousands, so 80 coins. 577 more steps earn the next 10.

The Today tab calls `GET /me`, which returns `{username, today, week, total, coins}`.

---

# Friends: request, then accept

1. **POST /friends/request**: send `{username}`. This creates a pending request.
2. **GET /friends**: returns `{friends, requests}`: your accepted friends, and requests people sent to you.
3. **POST /friends/{id}/accept**: accepts the request from that user id. Now you are friends both ways.

If they already asked you, sending a request to them counts as accepting.

---

# GET /leaderboard ranks you and your friends

- `?range=today`: steps from today only.
- `?range=week`: steps from today and the six days before.
- Only you and your accepted friends appear.
- Most steps first, and ties go in alphabetical order.
- The app refreshes the list every 5 seconds.

---

# The token page

```
Authorization: Bearer tt0-vM78dA…
```

- The server creates a random token when you sign up.
- The Profile tab shows it, so you can paste it into the Shortcut.
- The Shortcut sends it in the `Authorization` header on every request.
- Anyone with the token can send steps as you, so keep it private.
- Log out clears the login saved in the app.

---

# Tech stack

| Tool | What it is for |
|---|---|
| Python + uv | The language, and the tool that installs packages and runs the tests |
| FastAPI + uvicorn | Defines the routes, serves them, and builds the `/docs` page |
| SQLite | Stores users, steps, and friends in one file |
| Pydantic + scrypt | Checks request bodies, and hashes passwords |
| Flutter (Dart) | The app screens: Today, Leaderboard, Friends, Profile |
| iOS Shortcuts + Apple Health | Reads your steps and sends them to the server |
| Tailscale | A private network between the iPhone and the laptop |
| pytest + flutter_test | Unit, integration, regression, and acceptance tests |
| Marp + GitHub | Slides for the docs, and the code repository |

---

# Thank you

## Any questions?

github.com/DANTHAND005/step-quest
