---
marp: true
paginate: true
title: Step Quest Sprint 1 Retrospective
---

# Step Quest: Sprint 1 Retrospective

ASE420 Individual Project · Daniel Than

---

## Sprint 1 goal

Get the core loop working end to end:

- Real steps from my iPhone reach a Python server automatically
- 10 coins for every 1,000 steps
- Friends and a multiplayer leaderboard
- An app to see it all

---

## How I planned it

The plan changed a few times as I learned what was possible:

1. **Original idea:** loot crates with rarity tiers every 1,000 steps.
   Cut down to coins for Sprint 1 so the core loop works first.
2. **Website or app?** First planned a mobile website. Switched to a real app, since this is meant to be an app.
3. **No Mac:** a native iPhone app needs a Mac or a $99/year developer account.
   I only have Windows and an iPhone, and this is a class project, not an App Store release.
4. **Final plan:** a Flutter app on the PC, real steps from the iPhone through an iOS Shortcut,
   and a Python server in the middle. The server is the ASE420 graded part.

Rule for the whole project: keep it simple and make features easy for anyone to add.

---

## What I built

| Part | Result |
|---|---|
| Server | FastAPI + SQLite: accounts, step sync, coins, friends, leaderboard |
| Tests | 42 pytest tests: unit, integration, regression, acceptance |
| App | Flutter: login, Today, Leaderboard, Friends, Profile |
| Step sync | iOS Shortcut reads Apple Health and posts to the server 3 times a day |
| Network | Tailscale connects my phone to my PC |
| Repo | Public on GitHub: DANTHAND005/step-quest |

First real sync: **1,067 steps → 10 coins.**

---

## What went well

- **Simple structure paid off.** Logic files never touch HTTP, so every rule was easy to test.
- **Tests caught problems early.** The server had 39 passing tests before the app existed.
- **Server-side checks.** Step limits, token checks and login lockout were in from day one.
- **Saving per day instead of adding.** Syncing the same day twice replaces the number, so the Shortcut can run as often as it wants.
- **Cutting scope.** Moving crates to Sprint 2 meant the core loop actually works.

---

## What didn't go well

- **Plans changed several times** before I settled on Shortcut + Flutter + Python. Earlier research on iOS limits would have saved time.
- **The Flutter app was written before Flutter was installed,** so it couldn't be tested right away.
- **A file update didn't reach my PC**, which caused a confusing 404 until I checked the actual file.
- **The app can't run on friends' iPhones yet.** Multiplayer only works through the Shortcut and my PC.

---

## What was hard: setting up

| Problem | Fix |
|---|---|
| `uv` not recognized | Installed uv, then restarted the terminal so PATH updated |
| `flutter` not recognized | Cloned the Flutter SDK and added `flutter\bin` to PATH |
| First `flutter --version` hung for 25+ minutes | The Dart SDK download stalled. Cleared `bin\cache` and ran it again in plain PowerShell |
| Pasting many commands at once left PowerShell stuck at `>>` | Ctrl+C, then run commands one at a time |
| `flutter create` asked for Developer Mode | Turned on Developer Mode in Windows settings |
| Phone couldn't see the PC | Tailscale was only on the phone. Installed it on the PC with the same account |
| Server only reachable from the PC | Started it with `--host 0.0.0.0` |

---

## What was hard: the iPhone Shortcut

| Problem | Fix |
|---|---|
| Shortcuts can't easily send a nested JSON list | Added `POST /steps/today` that only needs `{"steps": N}` |
| Pasted the token with `{ "token": ...}` around it | Header must be `Bearer` + space + only the token |
| "Invalid HTTP request" | Hidden character from copy/paste. Deleted the header and typed it again |
| `404 Not Found` | Server was running an old `api.py`. Fixed the file and restarted |
| Apple Watch double counting | Group the Health samples by Day |

---

## What I learned

- Check platform limits first: iOS, Apple Health and the Mac requirement decided the whole architecture.
- When something fails, read the actual error and check the actual file, not what I think is there.
- Keep a short checklist of setup steps. The same issues will come up on any new machine.
- Small, testable pieces made every change safe.
- I used Claude as a pair programmer for planning, code and debugging. I reviewed the code and can explain how each part works.

---

## Sprint 2 plan

1. Loot crates: spend coins, roll rarity from common to mythic
2. Coin ledger table so spending is tracked
3. Item collection screen in the app
4. Deploy the server so it doesn't depend on my PC being on
5. User manual in Marp
6. More app tests
