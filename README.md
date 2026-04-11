# Cookya

Cookya is an **iOS (SwiftUI) kitchen app** for a single household: manage **pantry** and **grocery**, generate **recipes** from what you have (with dietary and location context), **cook** meals with pantry updates, and keep **saved recipes** and **cooked history** in one place. The day-to-day loop is: *pantry → decide what to cook → shop → cook → update pantry → repeat*.

This repository contains the **iPhone app** plus optional **backends** so you can run recipe generation and data sync **without putting an OpenAI API key inside the app you ship to your phone**.

---

## Repository layout

| Path | What it is |
|------|----------------|
| `cookya/` | iOS app (Xcode target `cookya`) |
| `worker/` | **Recommended** production-style backend: Cloudflare Worker (recipe relay + KV inventory + snapshot backup). See [`worker/README.md`](worker/README.md). |
| `backend/` | Optional **local** Node/Express relay for the same recipe API while developing. See [`backend/README.md`](backend/README.md). |
| `scripts/` | CLI helpers for simulator/device builds and tests (see [`SKILLS.md`](SKILLS.md)). |

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
4. Recipe generation and optional inventory/snapshot sync then talk to **your** Worker.

**Option B — Local relay on your Mac (good for hacking on the API)**  

1. Run the Express server from `backend/` per [`backend/README.md`](backend/README.md).  
2. Point `COOKYA_BACKEND_BASE_URL` at that URL (simulator often uses `http://localhost:…`; a physical device needs your Mac’s LAN IP or a tunnel).  
3. Still use a static `COOKYA_APP_TOKEN` in both the server env and the app (Keychain).

**Option C — Direct OpenAI from Xcode (not for shipping a standalone build with a key)**  

You can pass `OPENAI_API_KEY` via the Run scheme environment for local debugging only. Prefer Option A or B for anything you treat as a real install. Details: [`OPENAI_SETUP.md`](OPENAI_SETUP.md).

### 4. Backup and durability

- **Export/import** (files): Profile → Backup.  
- **Cloud snapshot** (optional): with the Worker + KV + app token, the app can sync a full snapshot to the backend; see [`worker/README.md`](worker/README.md) snapshot section.

### 5. CLI builds and tests (optional)

If you prefer terminal builds or CI-style checks, see [`SKILLS.md`](SKILLS.md) for `scripts/build-sim.sh`, `scripts/test-sim.sh`, and device builds (`COOKYA_DEVICE_ID`).

---

## Product and roadmap

For the current product narrative, what is built vs in progress, and engineering priorities, read [`PLANNING.md`](PLANNING.md).

---

## Security

- Do **not** commit `cookya/Config/Secrets.xcconfig`, `worker/.dev.vars`, or `backend/.env`.  
- Optional: enable the repo’s PII/secret pre-commit hook — [`SKILLS.md`](SKILLS.md) (“Prevent committing PII/secrets”).

---

## License

If no `LICENSE` file is present in the repository yet, treat usage as **all rights reserved** until the maintainer adds an explicit license.
