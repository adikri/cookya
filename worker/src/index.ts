type InventoryCategory =
  | "produce"
  | "dairy"
  | "meat"
  | "seafood"
  | "pantry"
  | "bakery"
  | "frozen"
  | "snacks"
  | "beverages"
  | "condiments"
  | "spices"
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
      const provided = getBearerToken(request);
      if (!provided || provided !== env.COOKYA_APP_TOKEN) {
        return jsonError("Unauthorized", 401);
      }

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

    return jsonError("Not found", 404);
  },
} satisfies ExportedHandler<Env>;

