# OpenAI Setup (Local)

1. Copy template:

```bash
cp cookya/Config/Secrets.xcconfig.example cookya/Config/Secrets.xcconfig
```

2. Open `cookya/Config/Secrets.xcconfig` and set:

- `OPENAI_API_KEY`
- `OPENAI_BASE_URL` (default: `https://api.openai.com`)
- `OPENAI_MODEL` (default: `gpt-4.1-mini`)

3. In Xcode, set one of these:

- Target `cookya` -> Build Settings -> `OPENAI_API_KEY` to your real key.
- Or Scheme -> Edit Scheme -> Run -> Environment Variables:
  - `OPENAI_API_KEY`
  - `OPENAI_BASE_URL` (optional)
  - `OPENAI_MODEL` (optional)

4. Build and run.

The app reads values from environment first, then Info.plist/build settings:
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `OPENAI_MODEL`

Do not commit real keys to git.
