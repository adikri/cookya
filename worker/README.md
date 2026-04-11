# Cookya Cloudflare Worker

Small HTTP edge service for **Cookya**: OpenAI-backed recipe generation, optional **KV-backed** pantry/grocery sync, and **full-app snapshot** backup/restore. Designed to run on Cloudflare’s free tier using a **static app token** (no OpenAI key in the iOS client).

For what Cookya is and how to run the **iOS app** on your own machine and phone, start at the repository root [`README.md`](../README.md).

## Prerequisites

- Node.js 18+ (for `npm` / Wrangler)
- A [Cloudflare](https://dash.cloudflare.com/) account
- An OpenAI API key (server-side only; stored as a Worker **secret** in production)

## Authentication

All `/v1/*` routes (except what is listed below) expect:

```http
Authorization: Bearer <COOKYA_APP_TOKEN>
```

Use a long random value for `COOKYA_APP_TOKEN`, set it with `wrangler secret put` in production, and store the same value in the app (Keychain) as documented in the main repo.

**Unauthenticated:** `GET /health` only.

## Endpoints

| Method | Path | Purpose |
|--------|------|--------|
| `GET` | `/health` | Liveness: `{ "ok": true }` |
| `POST` | `/v1/recipes/generate` | Recipe JSON (OpenAI); **requires bearer token**; **does not use KV** |
| `GET` | `/v1/pantry` | List pantry items (KV) |
| `PUT` | `/v1/pantry/:id` | Upsert one pantry item (KV) |
| `DELETE` | `/v1/pantry/:id` | Remove one pantry item (KV) |
| `GET` | `/v1/grocery` | List grocery items (KV) |
| `PUT` | `/v1/grocery/:id` | Upsert one grocery item (KV) |
| `DELETE` | `/v1/grocery/:id` | Remove one grocery item (KV) |
| `POST` | `/v1/grocery/:id/purchase` | Move item to pantry (KV) |
| `GET` | `/v1/snapshot` | Latest full backup JSON (KV), or `404` if none |
| `PUT` | `/v1/snapshot` | Replace latest full backup (KV); body must be JSON |

Inventory and snapshot routes return **503** if KV is not bound (see Setup).

## Storage and scoping (KV)

- Data lives under keys scoped from the **SHA-256 hash of the bearer token** (first 16 bytes, hex). The raw token is not stored as the KV key.
- New writes use **`v2:<scope>:…`** keys. Reads still fall back to legacy **`v1:*`** keys when no `v2` data exists yet, so existing deployments keep working until the next write.

## Rate limiting

`PUT`, `POST`, and `DELETE` under `/v1/*` are **best-effort** limited per token (currently **120 requests per minute**) to reduce accidental KV churn. `GET` is not limited by this counter.

## Local development

1. **Install dependencies**

   ```bash
   cd worker
   npm install
   ```

2. **Secrets for `wrangler dev`**

   ```bash
   cp .dev.vars.example .dev.vars
   ```

   Edit `.dev.vars` and set at least:

   - `OPENAI_API_KEY`
   - `COOKYA_APP_TOKEN`

   `.dev.vars` is git-ignored; do not commit it.

3. **KV (required for pantry / grocery / snapshot, not for `/health` or recipe-only tests)**

   Create preview + production namespace IDs and put them in `wrangler.toml` under `[[kv_namespaces]]` as `COOKYA_KV` (see the file in this folder for the expected shape).

   ```bash
   npx wrangler kv namespace create COOKYA_KV
   npx wrangler kv namespace create COOKYA_KV --preview
   ```

4. **Run the dev server**

   ```bash
   npm run dev
   ```

### Quick smoke checks

Replace `BASE` and `TOKEN` with your dev URL and `COOKYA_APP_TOKEN`.

```bash
curl -sS "$BASE/health"
curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/v1/pantry"
```

## Production deploy

1. **Login (once per machine)**

   ```bash
   npx wrangler login
   ```

2. **Configure KV** in `wrangler.toml` (same as local, using production namespace id).

3. **Set secrets** (values are not stored in git)

   ```bash
   npx wrangler secret put OPENAI_API_KEY
   npx wrangler secret put COOKYA_APP_TOKEN
   ```

4. **Deploy**

   ```bash
   npm run deploy
   ```

5. **Point the iOS app** at the Worker: set `COOKYA_BACKEND_BASE_URL` in local `Secrets.xcconfig` (or your scheme / env) to `https://<your-worker>.<subdomain>.workers.dev` with **no** trailing slash unless your app already expects one.

### Rotating the app token

Set a new secret, then update the token in the app (Profile → Backend access). Old clients using the old token will receive `401` until updated.

## Troubleshooting

| Symptom | Likely cause |
|--------|----------------|
| `503` on `/v1/pantry`, `/v1/grocery`, or `/v1/snapshot` | `COOKYA_KV` not bound in `wrangler.toml` or wrong namespace id |
| `401` on protected routes | Wrong or missing `Authorization: Bearer` header, or token mismatch with `COOKYA_APP_TOKEN` secret |
| `429` on writes | Per-token write rate limit; wait a minute or reduce sync frequency |
| `502` on recipe route | Upstream OpenAI error; check Worker logs and `OPENAI_API_KEY` |
| `curl` TLS errors right after deploy | Often transient DNS/TLS propagation; retry after a short wait |

## Security notes (public repo)

- Never commit `.dev.vars`, `OPENAI_API_KEY`, or `COOKYA_APP_TOKEN`.
- `wrangler.toml` may contain **KV namespace ids**; those identify resources in your account but are **not** authentication material. If you need the repo to stay free of infra ids, keep real ids in an untracked local override and commit a template only.
