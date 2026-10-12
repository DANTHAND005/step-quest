# iPhone Shortcut: send steps to Step Quest

This Shortcut reads today's steps from Apple Health and sends them to the server.

## You need

- The server running with `--host 0.0.0.0`, reachable from your phone. During development,
  install [Tailscale](https://tailscale.com) on your PC and iPhone (same account) and use your
  PC's Tailscale IP (starts with 100.).
- Your token. On the phone, open `http://<pc-ip>:8000/docs` → **POST /auth/login** → Try it out →
  Execute, and copy only the `token` value (no quotes or brackets).

## Build it

Open **Shortcuts** → **+** → name it **Sync Step Quest**. Add these actions:

1. **Find Health Samples**
   - Type: **Steps**
   - Start Date: **is today**
   - Group by: **Day** (matches the Health app total, no Apple Watch double counting)
2. **Calculate Statistics** → **Sum** of Health Samples
3. **Get Contents of URL**
   - URL: `http://<pc-ip>:8000/steps/today`
   - Method: **POST**
   - Headers: `Authorization` = `Bearer <your token>` (one space after Bearer, nothing after the token)
   - Request Body: **JSON** → add one **Number** field: `steps` = the **Sum** result
4. **Show Result** (optional) → shows the server's reply so you can see your coins.

Run it once and allow Health access and the network connection.

## Make it automatic

**Automation** tab → **+** → **Time of Day** → pick a time → **Run Immediately** → action:
**Run Shortcut** → *Sync Step Quest*.

Make three: around noon, 6 PM, and 11:55 PM. Each sync replaces today's number, so extra syncs are harmless.

## Troubleshooting

| Reply | Meaning |
|---|---|
| `{"today": ..., "coins": ...}` | Worked. |
| `Log in first` | Token is wrong. Re-copy only the token. |
| `Not Found` | URL is wrong, or the server is an older version. Restart it. |
| Invalid HTTP request | A hidden character in the header. Delete the header and type it again. |

## Sending more than one day

`POST /steps` takes `{"days": [{"date": "2026-10-10", "steps": 8423}, ...]}` (up to 31 days),
for backfilling missed days. The Shortcut doesn't need it.
