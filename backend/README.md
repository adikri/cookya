# Cookya backend (Phase 1 — Option A)

Minimal recipe-generation relay to support **standalone iPhone usage without bundling OpenAI keys**.

## What it does
- Exposes `POST /v1/recipes/generate`
- Requires `Authorization: Bearer <COOKYA_APP_TOKEN>`
- Calls OpenAI using `OPENAI_API_KEY` stored **server-side**
- Returns a JSON `Recipe` compatible with the iOS app

## Local dev

1. Install deps:

```bash
cd backend
npm install
```

2. Create env file (example values):

```bash
cp .env.example .env
```

3. Export env vars (or use your preferred dotenv loader):

```bash
set -a
source .env
set +a
```

4. Run:

```bash
npm run dev
```

Health check:
- `GET /health`

## iOS wiring
Set `COOKYA_BACKEND_BASE_URL` to `http://localhost:8787` (simulator) or to your deployed URL (device).

The iOS client currently posts to `/v1/recipes/generate` (see `cookya/Services/BackendRecipeService.swift`).

