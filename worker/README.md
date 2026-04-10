# Cookya recipe relay (Cloudflare Worker)

Free-tier friendly deployment for Phase 1 Option A (static token).

## Endpoints
- `GET /health` → `{ "ok": true }`
- `POST /v1/recipes/generate`
  - Requires header: `Authorization: Bearer <COOKYA_APP_TOKEN>`
  - Returns JSON `Recipe` compatible with the iOS app

## Setup

1. Install:

```bash
cd worker
npm install
```

2. Local dev secrets:

```bash
cp .dev.vars.example .dev.vars
```

Edit `.dev.vars` and set:
- `OPENAI_API_KEY`
- `COOKYA_APP_TOKEN`

3. Run locally:

```bash
npm run dev
```

## Deploy

1. Login:

```bash
npx wrangler login
```

2. Set secrets (production):

```bash
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put COOKYA_APP_TOKEN
```

3. Deploy:

```bash
npm run deploy
```

After deploy, set `COOKYA_BACKEND_BASE_URL` in the iOS app to your Worker URL.

