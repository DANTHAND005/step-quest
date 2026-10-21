---
marp: true
paginate: true
title: Step Quest Sprint 1 Review
style: |
  section { font-size: 28px; }
  table { font-size: 22px; }
---

# Step Quest: Sprint 1 Review

ASE420 Individual Project · Daniel Than

Walk, earn coins, beat your friends.
github.com/DANTHAND005/step-quest

---

# Demo

1. iPhone Shortcut reads today's steps from Apple Health
2. Sends `POST /steps/today` to the Python server over Tailscale
3. Flutter app shows Today, Leaderboard, Friends, Profile

First real sync: **1,067 steps → 10 coins**

---

# Sprint 1 metrics

| Metric | Value |
|---|---|
| Lines of code | 1,719: server 428, app 915, tests 376 |
| Features | 5 / 5 = 100% |
| Requirements | 10 / 10 = 100% |
| Remaining requirements | 0 |
| Tests | 42 passing: unit, integration, regression, acceptance |

Features: accounts, step tracking, coins, friends, leaderboard

---

# Burndown: remaining requirements

| | Start | Wk 5 | Wk 6 | Wk 7 | Wk 8 |
|---|---|---|---|---|---|
| Remaining | 10 | 10 | 10 | 4 | 0 |

- Weeks 5–6: planning, iOS research, picking the stack
- Week 7: server, database, tests, Flutter app
- Week 8: iPhone Shortcut sync, auto-refresh, docs

---

# Scope changes

- **Loot crates** moved to Sprint 2 so the core loop works first
- **Website → app:** Flutter app plus an iPhone Shortcut
- **No Mac:** a native iPhone app needs a Mac or $99/year, so steps come in through a Shortcut

Feature and requirement counts did not change.

---

# What went well

- Simple structure: every rule was easy to test
- 39 tests passed before the app existed, 42 now
- Step limits, token checks, and login lockout from day one
- Saving per day: syncing twice just replaces the number
- Cutting crates meant the whole loop works

---

# What went wrong

- Plans changed several times before settling on the stack
- Flutter app written before Flutter was installed
- Setup issues: uv, Flutter, PATH, Tailscale, Developer Mode
- Most code landed in the last few days of the sprint
- App can't run on friends' iPhones yet

---

# Improvements for Sprint 2

- Check platform limits before planning
- Commit small pieces every week, not all at the end
- Keep a setup checklist for new machines
- Read the actual error and the actual file first

---

# Design learning: Single Responsibility

- Logic files `auth.py`, `steps.py`, `social.py` never touch HTTP
- Routes in `api.py` only read the request and call one function
- Bad input = `raise ValueError`, turned into a 400 in one place

**Result:** the Shortcut needed a simpler route, so I added `POST /steps/today` as one thin route reusing the same save logic. No logic changed.

---

# Sprint 2 MVP: loot crates

- Spend coins on a crate
- Roll a rarity: common, uncommon, rare, epic, legendary, mythic
- Item collection screen in the app
- Coin ledger table so spending is tracked
- Deploy the server so it doesn't depend on my PC

---

# Sprint 2 test plan

| Type | What | File |
|---|---|---|
| Unit | Rarity odds, coin balance, can't overspend | `tests/unit/test_crates.py` |
| Integration | Open-crate and collection routes | `tests/integration/test_api_crates.py` |
| Regression | One test per fixed bug | `tests/regression/test_regressions.py` |
| Acceptance | Walk → coins → open crate → see item | `tests/acceptance/test_user_stories.py` |

---

# Sprint 2 timeline

| Weeks | Plan |
|---|---|
| 9–10 | Coin ledger, open-crate route, rarity roll, unit tests |
| 11–12 | Collection screen, integration tests, deploy server |
| 13 | Acceptance tests, docs, GitHub Pages site |
| 14–15 | Fixes, final demo, submission |

---

# Thank you

## Questions?

github.com/DANTHAND005/step-quest
