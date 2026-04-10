/// <reference types="@cloudflare/workers-types" />

type InventoryCategory =
  | "produce"
  | "dairy"
  | "protein"
  | "grains"
  | "spices"
  | "beverages"
  | "frozen"
  | "canned"
  | "bakery"
  | "pantry"
  | "snacks"
  | "other";

type Difficulty = "easy" | "medium" | "hard";

type BackendPantryItem = {
  id: string;
  name: string;
  availableQuantityText: string;
  selectedQuantityText: string;
  category: InventoryCategory;
  expiryDate: string | null;
};

type Ingredient = { name: string; quantity: string };

type UserProfile = {
  isVegetarian?: boolean;
  avoidFoodItems?: string[];
  location?: string;
};

type BackendRecipeGenerateRequest = {
  pantryItems: BackendPantryItem[];
  manualIngredients: Ingredient[];
  difficulty: Difficulty;
  servings: number;
  profile?: UserProfile | null;
  prioritizedIngredientNames: string[];
  locationContext?: string | null;
};

type Recipe = {
  title: string;
  ingredients: Ingredient[];
  instructions: string[];
  calories: number;
  difficulty: Difficulty;
};

type Env = {
  OPENAI_API_KEY: string;
  COOKYA_APP_TOKEN: string;
  COOKYA_KV?: KVNamespace;
  OPENAI_BASE_URL?: string;
  OPENAI_MODEL?: string;
};

function json(data: unknown, init?: ResponseInit): Response {
  return new Response(JSON.stringify(data), {
    ...init,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...(init?.headers ?? {}),
    },
  });
}

function jsonError(message: string, status: number): Response {
  return json({ error: { message } }, { status });
}

function getBearerToken(request: Request): string | null {
  const header = request.headers.get("authorization");
  if (!header) return null;
  const m = header.match(/^Bearer\s+(.+)$/i);
  return m?.[1]?.trim() ?? null;
}

function notFound(): Response {
  return jsonError("Not found", 404);
}

function requireAuth(request: Request, env: Env): Response | null {
  const provided = getBearerToken(request);
  if (!provided || provided !== env.COOKYA_APP_TOKEN) {
    return jsonError("Unauthorized", 401);
  }
  return null;
}

function requireKV(env: Env): KVNamespace | Response {
  if (!env.COOKYA_KV) {
    return jsonError(
      "Sync storage not configured. Bind a KV namespace as COOKYA_KV in wrangler.toml.",
      503,
    );
  }
  return env.COOKYA_KV;
}

type PantryItem = {
  id: string;
  name: string;
  quantityText: string;
  category: InventoryCategory;
  expiryDate: string | null;
  updatedAt: string;
};

type GroceryItemSource = "manual" | "savedRecipe" | "cookedRecipe" | "extraIngredient";

type GroceryItem = {
  id: string;
  name: string;
  quantityText: string;
  category: InventoryCategory;
  note: string | null;
  source: GroceryItemSource;
  reasonRecipes: string[];
  createdAt: string;
};

function nowIso(): string {
  return new Date().toISOString();
}

function kvKey(scope: "pantry" | "grocery" | "snapshot"): string {
  // v1: single household scope per Worker token.
  return `v1:${scope}`;
}

async function kvGetJson<T>(kv: KVNamespace, key: string, fallback: T): Promise<T> {
  const raw = await kv.get(key);
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

async function kvPutJson(kv: KVNamespace, key: string, value: unknown): Promise<void> {
  await kv.put(key, JSON.stringify(value));
}

function buildUserPrompt(body: BackendRecipeGenerateRequest): string {
  const ingredientRows = [
    ...(body.manualIngredients ?? []),
    ...(body.pantryItems ?? []).map((p) => ({
      name: p.name,
      quantity: p.selectedQuantityText?.trim()
        ? p.selectedQuantityText
        : "not specified",
    })),
  ];

  const pantryRows = (body.pantryItems ?? []).map((p) => ({
    name: p.name,
    availableQuantity: p.availableQuantityText,
    selectedQuantity: p.selectedQuantityText?.trim()
      ? p.selectedQuantityText
      : "not specified",
    category: p.category,
    expiryDate: p.expiryDate ?? "none",
  }));

  const prioritized =
    body.prioritizedIngredientNames?.filter(Boolean).join(", ") ?? "";
  const avoidFoods =
    body.profile?.avoidFoodItems?.filter(Boolean).join(", ") ?? "none";
  const location =
    body.profile?.location ?? body.locationContext ?? "not provided";
  const dietary =
    body.profile?.isVegetarian === true
      ? "vegetarian"
      : "no vegetarian restriction";

  return [
    "Create one home-cooking recipe using these ingredients and requested difficulty.",
    "",
    "Ingredients:",
    JSON.stringify(ingredientRows),
    "",
    "Pantry context:",
    JSON.stringify(pantryRows),
    "",
    `Difficulty: ${body.difficulty}`,
    `Servings: ${body.servings}`,
    `Dietary preference: ${dietary}`,
    `Avoid foods/allergens: ${avoidFoods}`,
    `Location context: ${location}`,
    `Prioritize these ingredients first if possible: ${prioritized.length ? prioritized : "none"}`,
    "",
    "Hard constraints:",
    "- Never include any avoid foods.",
    "- If vegetarian is requested, do not include meat, fish, or seafood.",
    "- Keep recipe realistic for home cooking.",
    `- Make the recipe suitable for exactly ${body.servings} serving(s).`,
    "- If a selected pantry quantity is provided, treat it as the target amount to use for that ingredient.",
    "",
    "Output only JSON matching the schema exactly.",
  ].join("\n");
}

async function callOpenAI(body: BackendRecipeGenerateRequest, env: Env): Promise<Recipe> {
  const baseURL = (env.OPENAI_BASE_URL?.trim() || "https://api.openai.com").replace(/\/+$/, "");
  const model = env.OPENAI_MODEL?.trim() || "gpt-4.1-mini";
  const url = `${baseURL}/v1/chat/completions`;

  const requestBody = {
    model,
    messages: [
      {
        role: "system",
        content:
          "You are a recipe assistant. Return only strict JSON that follows the provided schema. No markdown, no extra text.",
      },
      { role: "user", content: buildUserPrompt(body) },
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "recipe_response",
        strict: true,
        schema: {
          type: "object",
          additionalProperties: false,
          required: ["title", "ingredients", "instructions", "calories", "difficulty"],
          properties: {
            title: { type: "string" },
            ingredients: {
              type: "array",
              items: {
                type: "object",
                additionalProperties: false,
                required: ["name", "quantity"],
                properties: {
                  name: { type: "string" },
                  quantity: { type: "string" },
                },
              },
            },
            instructions: { type: "array", items: { type: "string" }, minItems: 1 },
            calories: { type: "integer", minimum: 0 },
            difficulty: { type: "string", enum: ["easy", "medium", "hard"] },
          },
        },
      },
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${env.OPENAI_API_KEY}`,
    },
    body: JSON.stringify(requestBody),
  });

  const text = await resp.text();
  if (!resp.ok) {
    let message = `OpenAI error (${resp.status})`;
    try {
      const j = JSON.parse(text) as any;
      if (j?.error?.message) message = `OpenAI error (${resp.status}): ${j.error.message}`;
    } catch {
      // ignore
    }
    throw new Error(message);
  }

  const completion = JSON.parse(text) as any;
  const content: string | null | undefined = completion?.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI response missing message content");

  return JSON.parse(content) as Recipe;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true }, { status: 200 });
    }

    if (request.method === "POST" && url.pathname === "/v1/recipes/generate") {
      const authError = requireAuth(request, env);
      if (authError) return authError;

      let body: BackendRecipeGenerateRequest;
      try {
        body = (await request.json()) as BackendRecipeGenerateRequest;
      } catch {
        return jsonError("Invalid JSON body", 400);
      }

      try {
        const recipe = await callOpenAI(body, env);
        return json(recipe, { status: 200 });
      } catch (e) {
        const message = e instanceof Error ? e.message : "Unknown server error";
        return jsonError(message, 502);
      }
    }

    if (url.pathname.startsWith("/v1/")) {
      const authError = requireAuth(request, env);
      if (authError) return authError;

      const kvOrResponse = requireKV(env);
      if (kvOrResponse instanceof Response) return kvOrResponse;
      const kv = kvOrResponse;

      // Snapshot (full app state backup)
      if (url.pathname === "/v1/snapshot") {
        const key = kvKey("snapshot" as any);
        if (request.method === "GET") {
          const raw = await kv.get(key);
          if (!raw) return notFound();
          return new Response(raw, {
            status: 200,
            headers: { "content-type": "application/json; charset=utf-8" },
          });
        }
        if (request.method === "PUT") {
          const raw = await request.text();
          try {
            JSON.parse(raw);
          } catch {
            return jsonError("Invalid JSON body", 400);
          }
          await kv.put(key, raw);
          return json({ ok: true }, { status: 200 });
        }
        return notFound();
      }

      // Pantry
      if (request.method === "GET" && url.pathname === "/v1/pantry") {
        const pantry = await kvGetJson<PantryItem[]>(kv, kvKey("pantry"), []);
        return json(pantry, { status: 200 });
      }

      const pantryMatch = url.pathname.match(/^\/v1\/pantry\/([^/]+)$/);
      if (pantryMatch) {
        const id = pantryMatch[1];
        if (request.method === "PUT") {
          let body: PantryItem;
          try {
            body = (await request.json()) as PantryItem;
          } catch {
            return jsonError("Invalid JSON body", 400);
          }
          const pantry = await kvGetJson<PantryItem[]>(kv, kvKey("pantry"), []);
          const updated: PantryItem = {
            ...body,
            id,
            updatedAt: body.updatedAt?.trim() ? body.updatedAt : nowIso(),
          };
          const idx = pantry.findIndex((p) => p.id === id);
          if (idx >= 0) pantry[idx] = updated;
          else pantry.push(updated);
          await kvPutJson(kv, kvKey("pantry"), pantry);
          return json(updated, { status: 200 });
        }
        if (request.method === "DELETE") {
          const pantry = await kvGetJson<PantryItem[]>(kv, kvKey("pantry"), []);
          const next = pantry.filter((p) => p.id !== id);
          await kvPutJson(kv, kvKey("pantry"), next);
          return json({}, { status: 200 });
        }
        return notFound();
      }

      // Grocery
      if (request.method === "GET" && url.pathname === "/v1/grocery") {
        const grocery = await kvGetJson<GroceryItem[]>(kv, kvKey("grocery"), []);
        return json(grocery, { status: 200 });
      }

      const groceryMatch = url.pathname.match(/^\/v1\/grocery\/([^/]+)$/);
      if (groceryMatch) {
        const id = groceryMatch[1];
        if (request.method === "PUT") {
          let body: GroceryItem;
          try {
            body = (await request.json()) as GroceryItem;
          } catch {
            return jsonError("Invalid JSON body", 400);
          }
          const grocery = await kvGetJson<GroceryItem[]>(kv, kvKey("grocery"), []);
          const updated: GroceryItem = { ...body, id };
          const idx = grocery.findIndex((g) => g.id === id);
          if (idx >= 0) grocery[idx] = updated;
          else grocery.push(updated);
          await kvPutJson(kv, kvKey("grocery"), grocery);
          return json(updated, { status: 200 });
        }
        if (request.method === "DELETE") {
          const grocery = await kvGetJson<GroceryItem[]>(kv, kvKey("grocery"), []);
          const next = grocery.filter((g) => g.id !== id);
          await kvPutJson(kv, kvKey("grocery"), next);
          return json({}, { status: 200 });
        }
        return notFound();
      }

      const purchaseMatch = url.pathname.match(/^\/v1\/grocery\/([^/]+)\/purchase$/);
      if (purchaseMatch && request.method === "POST") {
        const id = purchaseMatch[1];
        let body: GroceryItem;
        try {
          body = (await request.json()) as GroceryItem;
        } catch {
          return jsonError("Invalid JSON body", 400);
        }

        const grocery = await kvGetJson<GroceryItem[]>(kv, kvKey("grocery"), []);
        const nextGrocery = grocery.filter((g) => g.id !== id);
        await kvPutJson(kv, kvKey("grocery"), nextGrocery);

        const pantry = await kvGetJson<PantryItem[]>(kv, kvKey("pantry"), []);
        const pantryItem: PantryItem = {
          id: crypto.randomUUID(),
          name: body.name,
          quantityText: body.quantityText ?? "",
          category: body.category ?? "pantry",
          expiryDate: null,
          updatedAt: nowIso(),
        };
        pantry.push(pantryItem);
        await kvPutJson(kv, kvKey("pantry"), pantry);
        return json(pantryItem, { status: 200 });
      }
    }

    return jsonError("Not found", 404);
  },
} satisfies ExportedHandler<Env>;

