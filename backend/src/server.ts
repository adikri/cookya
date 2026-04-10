import express from "express";
import crypto from "crypto";
import { generateRecipeWithOpenAI } from "./openai.js";
import type { BackendRecipeGenerateRequest, ErrorResponse } from "./types.js";

function jsonError(message: string): ErrorResponse {
  return { error: { message } };
}

function env(name: string): string | undefined {
  const v = process.env[name];
  if (!v) return undefined;
  const trimmed = v.trim();
  return trimmed.length ? trimmed : undefined;
}

function requireBearerToken(req: express.Request): string | null {
  const header = req.header("authorization") ?? req.header("Authorization");
  if (!header) return null;
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() ?? null;
}

// Simple in-memory rate limiting per token (dev-grade).
// This is intentionally small and easy to replace with a real store later.
const rate = new Map<string, { windowStartMs: number; count: number }>();
const RATE_WINDOW_MS = 60_000;
const RATE_MAX_PER_WINDOW = 30;

function isRateLimited(token: string, nowMs: number): boolean {
  const cur = rate.get(token);
  if (!cur || nowMs - cur.windowStartMs >= RATE_WINDOW_MS) {
    rate.set(token, { windowStartMs: nowMs, count: 1 });
    return false;
  }
  cur.count += 1;
  return cur.count > RATE_MAX_PER_WINDOW;
}

const app = express();
app.disable("x-powered-by");
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

app.post("/v1/recipes/generate", async (req, res) => {
  const requestId = crypto.randomUUID();

  const expectedToken = env("COOKYA_APP_TOKEN");
  if (!expectedToken) {
    res.status(500).json(jsonError("Server missing COOKYA_APP_TOKEN"));
    return;
  }

  const provided = requireBearerToken(req);
  if (!provided || provided !== expectedToken) {
    res.status(401).json(jsonError("Unauthorized"));
    return;
  }

  const now = Date.now();
  if (isRateLimited(provided, now)) {
    res.status(429).json(jsonError("Rate limit reached. Please try again later."));
    return;
  }

  const body = req.body as BackendRecipeGenerateRequest;
  if (!body || typeof body !== "object") {
    res.status(400).json(jsonError("Invalid JSON body"));
    return;
  }

  try {
    const recipe = await generateRecipeWithOpenAI(body);
    res
      .status(200)
      .setHeader("X-Request-Id", requestId)
      .json(recipe);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown server error";
    res
      .status(502)
      .setHeader("X-Request-Id", requestId)
      .json(jsonError(message));
  }
});

const port = Number(env("PORT") ?? "8787");
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`cookya-backend listening on http://localhost:${port}`);
});

