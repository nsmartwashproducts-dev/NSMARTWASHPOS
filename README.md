# N-Smart Wash POS — Netlify Deploy (site + API, one folder)

This folder is the **whole app**: the POS PWA (`index.html`, `manifest.json`,
`sw.js`, icons) **plus** a real serverless API (`netlify/functions/`) that
talks to your Supabase database using a secret key that never touches the
browser. No npm install, no build step, no CLI required.

## Endpoints (once deployed)

| Method | URL                                | Purpose                    |
|--------|-------------------------------------|-----------------------------|
| GET    | `/api/health`                       | Health check (no auth)      |
| GET    | `/api/products`                     | List products                |
| POST   | `/api/products`                     | Create/update a product      |
| DELETE | `/api/products?id=X`                | Delete a product             |
| GET    | `/api/sales?from=YYYY-MM-DD&to=...` | List sales                   |
| POST   | `/api/sales`                        | Record/update a sale         |
| DELETE | `/api/sales?id=X`                   | Delete a sale                |
| GET    | `/api/settings`                     | Get business settings        |
| PUT    | `/api/settings`                     | Update business settings     |

---

## Fastest path — Netlify Drop (no account required to try, ~2 minutes)

1. Make sure you've already run `schema.sql` in your Supabase project's SQL
   Editor once (see the original `setup_guide.md` if not).
2. Go to **https://app.netlify.com/drop**
3. Drag this entire folder (the one containing `netlify.toml`, `index.html`,
   `netlify/`, etc.) onto the page.
4. Netlify gives you a live URL in seconds, e.g. `https://random-name-123.netlify.app`.

**One extra step to make the API work:** Netlify Drop deploys don't ask for
environment variables during the drag-and-drop itself, so you add them right
after:

5. Click **"Claim your site"** / sign up (free, no credit card) so the site
   is saved to your account instead of expiring.
6. Go to **Site configuration → Environment variables → Add a variable**,
   and add:
   - `SUPABASE_URL` = `https://YOUR-PROJECT-REF.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` = your Supabase **service_role** key
     (Supabase → Project Settings → API — the secret one, not anon)
   - `ALLOWED_ORIGIN` = your Netlify site URL, e.g. `https://random-name-123.netlify.app`
     (or leave as `*` while testing)
7. Go to **Deploys → Trigger deploy → Deploy site** so the functions pick up
   the new variables.
8. Test it: open `https://your-site.netlify.app/api/health` — you should see
   `{"status":"ok",...}`. Then `https://your-site.netlify.app/api/products`
   should return your product list from Supabase.

That's it — the site is live, installable as an app (per `install_guide.md`),
and has a real backend API.

---

## Alternative: Git-based deploy (auto-redeploys on every code change)

If you'd rather connect this to GitHub so future edits redeploy automatically:

1. Push this folder to a new GitHub repo.
2. In Netlify: **Add new site → Import an existing project → GitHub** → pick
   the repo.
3. Build settings: leave **Build command** blank, **Publish directory** = `.`
   (Netlify auto-detects `netlify/functions` from `netlify.toml`).
4. Add the same three environment variables as above under **Site
   configuration → Environment variables** before the first deploy.
5. Click **Deploy site**.

---

## Alternative: Netlify CLI (if you want a terminal workflow)

```bash
npm install -g netlify-cli
netlify login
netlify deploy --prod
```
Then set the environment variables either via the Netlify dashboard (above)
or:
```bash
netlify env:set SUPABASE_URL "https://YOUR-PROJECT-REF.supabase.co"
netlify env:set SUPABASE_SERVICE_ROLE_KEY "your-service-role-key"
netlify env:set ALLOWED_ORIGIN "https://your-site.netlify.app"
netlify deploy --prod
```

---

## Local testing (optional)

```bash
npm install -g netlify-cli
netlify dev
```
This runs the whole site + functions on `http://localhost:8888`, reading
variables from a local `.env` file if you create one (see `.env.example`).

---

## What this does NOT do

- I still can't click any of these buttons or run these commands for you —
  I have no network access or Netlify/Supabase account in this environment.
  Every step above is something you run yourself, but Netlify Drop in
  particular is genuinely just "drag folder → get URL", no CLI needed.
- This uses your existing Supabase Postgres database (`schema.sql`) — same
  data, just accessed through a secured API instead of directly from the
  browser with the public anon key.
- Once live, `index.html` still reads/writes Supabase directly via the anon
  key unless you rewire it to call `/api/products` etc. instead — I can do
  that edit for you now if you'd like (it's a small change to the
  `sbConfig()` section).
