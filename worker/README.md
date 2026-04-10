# Cookya recipe relay (Cloudflare Worker)

Free-tier friendly deployment for Phase 1 Option A (static token).

## Endpoints
- `GET /health` → `{ "ok": true }`
- `POST /v1/recipes/generate`
  - Requires header: `Authorization: Bearer <COOKYA_APP_TOKEN>`
  - Returns JSON `Recipe` compatible with the iOS app
- Inventory sync (used by the iOS app):
  - `GET /v1/pantry`
  - `PUT /v1/pantry/:id`
  - `DELETE /v1/pantry/:id`
  - `GET /v1/grocery`
  - `PUT /v1/grocery/:id`
  - `DELETE /v1/grocery/:id`
  - `POST /v1/grocery/:id/purchase`
  - Requires header: `Authorization: Bearer <COOKYA_APP_TOKEN>`
- Snapshot backup (reinstall-safe restore):
  - `GET /v1/snapshot`
  - `PUT /v1/snapshot`
  - Requires header: `Authorization: Bearer <COOKYA_APP_TOKEN>`

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

3. Sync storage (KV):

The inventory endpoints need a KV namespace binding called `COOKYA_KV`.

```bash
npx wrangler kv namespace create COOKYA_KV
npx wrangler kv namespace create COOKYA_KV --preview
```

Then add the generated IDs into `wrangler.toml` under the `[[kv_namespaces]]` binding (see the commented template in `wrangler.toml`).

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

