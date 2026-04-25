# Cookya

Cookya is a **household cooking assistant** — manage **pantry** and **grocery**, generate **recipes** from what you have, track **nutrition goals**, plan meals for the week, and keep **saved recipes** and **cooked history** in one place. The day-to-day loop is: *pantry → decide what to cook → shop → cook → update pantry → repeat*.

The iOS SwiftUI app is the personal daily driver and feature test bed. An Android React Native app targeting the Play Store is in development, sharing the same Supabase backend.

This repository contains the **iPhone app** plus optional **backends** so you can run recipe generation and data sync **without putting an OpenAI API key inside the app you ship to your phone**.

---

## Repository layout

| Path | What it is |
|------|----------------|
| `cookya/` | iOS SwiftUI app (personal daily driver + feature prototype) |
| `mobile/` | Android React Native app (Expo managed workflow) — public Play Store target |
| `worker/` | Cloudflare Worker — **OpenAI recipe relay only** (inventory and snapshot moved to Supabase). See [`worker/README.md`](worker/README.md). |
| `backend/` | Optional local Node/Express relay for development. See [`backend/README.md`](backend/README.md). |
| `supabase/` | Database migrations for the Supabase PostgreSQL backend. |
| `scripts/` | CLI helpers for simulator/device builds. See [`CLAUDE.md`](CLAUDE.md). |

---

## Use it on your own

You need a **Mac with Xcode** (current project targets recent iOS / Swift 6). You do **not** need to publish the app to the App Store to use it on your own iPhone: build and run from Xcode with your Apple ID (personal team or paid team for longer-lived installs).

### 1. Clone and open the project

```bash
git clone <repository-url>
cd cookya
open cookya.xcodeproj
```

### 2. Local configuration (never commit real secrets)

```bash
cp cookya/Config/Secrets.xcconfig.example cookya/Config/Secrets.xcconfig
```

Edit `cookya/Config/Secrets.xcconfig` for non-secret defaults (backend URL, model name, etc.). The real `Secrets.xcconfig` file is **git-ignored**.

Full detail: [`OPENAI_SETUP.md`](OPENAI_SETUP.md).

### 3. Choose how recipes (and optional sync) are powered

**Option A — Cloudflare Worker (good for “phone only, no Xcode” day-to-day)**  

1. Deploy the Worker and set secrets (`OPENAI_API_KEY`, `COOKYA_APP_TOKEN`). Step-by-step: [`worker/README.md`](worker/README.md).  
2. In `Secrets.xcconfig`, set `COOKYA_BACKEND_BASE_URL` to your Worker base URL (no secret keys in the app bundle for OpenAI).  
3. On the device: **Profile → Backend access** — paste the same long random value you set as `COOKYA_APP_TOKEN` on the Worker (stored in Keychain).  
4. Recipe generation then talks to **your** Worker. Inventory sync and app snapshot backup are handled by Supabase, not the Worker.

**Option B — Local relay on your Mac (good for hacking on the API)**  

1. Run the Express server from `backend/` per [`backend/README.md`](backend/README.md).  
2. Point `COOKYA_BACKEND_BASE_URL` at that URL (simulator often uses `http://localhost:…`; a physical device needs your Mac’s LAN IP or a tunnel).  
3. Still use a static `COOKYA_APP_TOKEN` in both the server env and the app (Keychain).

**Option C — Direct OpenAI from Xcode (not for shipping a standalone build with a key)**  

You can pass `OPENAI_API_KEY` via the Run scheme environment for local debugging only. Prefer Option A or B for anything you treat as a real install. Details: [`OPENAI_SETUP.md`](OPENAI_SETUP.md).

### 4. Supabase setup (auth + sync)

The app now uses **Supabase** for authentication and data sync. Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in `Secrets.xcconfig` (both are safe to bundle — Row Level Security policies protect data access).

- **Auth**: email/password sign-in and sign-up are built in.
- **Pantry/grocery sync**: live via `pantry_items` and `grocery_items` tables.
- **App snapshot backup**: full backup stored as JSONB in `user_snapshots` — restores automatically on reinstall/new device.
- **Schema migrations**: `supabase/migrations/` — apply via the Supabase SQL editor.

### 5. Backup and durability

- **Export/import** (files): Profile → Backup.
- **Cloud backup** (Supabase): automatic — syncs on every app state change. Restores on fresh install when local state is empty.
- **Worker KV snapshot**: deprecated — Cloudflare Worker is now OpenAI relay only.

### 6. CLI builds (optional)

See [`CLAUDE.md`](CLAUDE.md) for `scripts/build-sim.sh` and device builds (`COOKYA_DEVICE_ID`). Tests are run manually in Xcode.

---

## Product and roadmap

For the current product narrative, what is built vs in progress, and engineering priorities, read [`PLANNING.md`](PLANNING.md).

---

## Security

- Do **not** commit `cookya/Config/Secrets.xcconfig`, `worker/.dev.vars`, or `backend/.env`.  
- Optional: enable the repo’s PII/secret pre-commit hook via `git config core.hooksPath .githooks`.

---

## License

If no `LICENSE` file is present in the repository yet, treat usage as **all rights reserved** until the maintainer adds an explicit license.
