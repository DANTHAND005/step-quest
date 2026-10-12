---
marp: true
paginate: true
title: Step Quest User Manual
---

# Step Quest: User Manual

ASE420 Individual Project · Daniel Than

Walk, earn coins, compete with friends. Every 1,000 steps = 10 coins.

---

# What Step Quest does

- Counts your steps automatically from Apple Health. No manual entry.
- Turns steps into coins: every 1,000 steps earns 10 coins.
- Lets you add friends and compete on a daily or weekly leaderboard.

Three parts work together:

iPhone Shortcut → Python server → Flutter app

---

# What you need

- A PC that runs the server and stays on
- uv, to run the Python server
- Flutter, to run the app
- An iPhone with the Health app and the Shortcuts app
- Tailscale on the PC and the iPhone, with the same account, so the phone can reach the server

---

# Start the server

In a terminal:

```
cd server
uv sync
uv run uvicorn stepquest.main:app --reload --host 0.0.0.0
```

Open http://localhost:8000/docs to try every route in the browser.

---

# Start the app

Keep the server running. In a second terminal:

```
cd app
flutter create --project-name step_quest --platforms=web,windows,android .
flutter pub get
flutter run -d chrome
```

The `flutter create` line is only needed the first time.

---

# Create an account and log in

1. Open the app.
2. Choose the option to create an account.
3. Enter a username and a password.
4. Next time, log in with the same username and password.

After 5 wrong passwords, the username is locked for 15 minutes.

---

# Today tab

Shows:

- Your steps today
- Your last 7 days
- Your coins
- Your progress toward the next coins

The tab refreshes by itself every 5 seconds. Pull down to refresh it right away.

---

# Leaderboard tab

- Ranks you and your friends by steps.
- Switch between today and the last 7 days.
- Refreshes by itself every 5 seconds.

---

# Friends tab

- Add a friend by their username.
- Accept a friend request that someone sent you.
- See your friend list.

Once a request is accepted, you appear on each other's leaderboard.

---

# Profile tab

- Shows your token, which the iPhone Shortcut needs.
- Log out.

Keep your token private. Anyone who has it can send steps as you.

---

# Set up the iPhone Shortcut

In the Shortcuts app, make a new shortcut named Sync Step Quest with these actions:

1. Find Health Samples: type Steps, start date is today, group by Day
2. Calculate Statistics: Sum of the Health Samples
3. Get Contents of URL: http://PC-IP:8000/steps/today, method POST
   - Header: Authorization = Bearer YOUR-TOKEN
   - Body: JSON with one number field, steps, set to the Sum
4. Show Result (optional)

---

# Make the Shortcut automatic

In the Automation tab:

1. Tap + and choose Time of Day.
2. Pick a time and choose Run Immediately.
3. Add the action Run Shortcut and pick Sync Step Quest.

Make three: around noon, 6 PM, and 11:55 PM. Each sync replaces today's number, so extra syncs do no harm.

---

# Troubleshooting

| Reply | Meaning |
|---|---|
| Today and coins numbers | It worked |
| Log in first | The token is wrong. Copy only the token. |
| Not Found | The URL is wrong, or the server is an older version. Restart it. |
| Invalid HTTP request | A hidden character in the header. Delete it and type it again. |

---

# Known limits

- The server runs on one PC, so the PC has to be on.
- The app runs in Chrome or Windows. Friends can't install it on an iPhone yet.
- Steps come from the user's phone, so someone could send fake numbers. A daily limit of 100,000 steps reduces the damage. It's fine for a game between friends.
