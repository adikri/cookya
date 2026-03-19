# OpenAI Setup (Local)

1. Copy template:

```bash
cp cookya/Config/Secrets.xcconfig.example cookya/Config/Secrets.xcconfig
```

2. Open `cookya/Config/Secrets.xcconfig` and set:

- `OPENAI_API_KEY`
- `OPENAI_BASE_URL` (default: `https://api.openai.com`)
- `OPENAI_MODEL` (default: `gpt-4.1-mini`)
- `COOKYA_BACKEND_BASE_URL` (for backend-powered recipe generation and inventory sync)

3. Cookya now reads local build config values automatically if you create the secrets file above. That means the app can run on your phone away from Xcode after one rebuild.

4. Optional fallback for local debugging:

- Target `cookya` -> Build Settings -> `OPENAI_API_KEY` to your real key.
- Or Scheme -> Edit Scheme -> Run -> Environment Variables:
  - `OPENAI_API_KEY`
  - `OPENAI_BASE_URL` (optional)
  - `OPENAI_MODEL` (optional)
  - `COOKYA_BACKEND_BASE_URL` (optional, but required for backend mode)

5. Build and run.

The app reads values from environment first, then Info.plist/build settings:
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `OPENAI_MODEL`
- `COOKYA_BACKEND_BASE_URL`

Do not commit real keys to git.
