# iPhone Shortcut: send steps to Step Quest

This Shortcut reads today's steps from Apple Health and sends them to the server.

## You need

- The server running and reachable from your phone. During development, install
  [Tailscale](https://tailscale.com) on your PC and iPhone, and use your PC's Tailscale IP.
- Your token: the `token` you got back from `/auth/signup` or `/auth/login`.

## Build it

Open **Shortcuts** → **+** → name it **Sync Step Quest**. Add these actions in order:

1. **Find Health Samples**
   - Type: **Steps**
   - Start Date: **is today**
   - Group By: **Day** (this gives one total per day, the same number the Health app shows,
     so iPhone and Apple Watch steps aren't counted twice)
2. **Calculate Statistics** → **Sum** of Health Samples
3. **Format Date** → Current Date → Custom format: `yyyy-MM-dd`
4. **Get Contents of URL**
   - URL: `http://<your-pc-tailscale-ip>:8000/steps`
   - Method: **POST**
   - Headers: `Authorization` = `Bearer <your token>`
   - Request Body: **JSON**
     - `days` → type **Array**
       - one item, type **Dictionary**:
         - `date` (Text) = **Formatted Date**
         - `steps` (Number) = **Statistics Result**
5. *(optional)* **Show Notification** → Contents of URL, so you can see your coins.

Run it once. The first time, allow Health access.

**Check accuracy:** compare the steps in the reply with today's number in the Health app.
If they don't match, change step 1's source to **iPhone** only.

## Make it automatic

**Automation** tab → **+** → **Time of Day** → pick a time → **Run Immediately** → action: **Run Shortcut** → *Sync Step Quest*.

Make three: around noon, 6 PM, and 11:55 PM. Each sync replaces that day's number, so extra syncs are harmless.
