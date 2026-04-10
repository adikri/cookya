import type { BackendRecipeGenerateRequest, Recipe } from "./types.js";

type OpenAIChatCompletionResponse = {
  choices: Array<{
    message: {
      content: string | null;
    };
  }>;
};

function env(name: string): string | undefined {
  const v = process.env[name];
  if (!v) return undefined;
  const trimmed = v.trim();
  return trimmed.length ? trimmed : undefined;
}

export function getOpenAIConfig(): {
  apiKey: string;
  baseURL: string;
  model: string;
} {
  const apiKey = env("OPENAI_API_KEY");
  if (!apiKey) throw new Error("Missing OPENAI_API_KEY");

  return {
    apiKey,
    baseURL: env("OPENAI_BASE_URL") ?? "https://api.openai.com",
    model: env("OPENAI_MODEL") ?? "gpt-4.1-mini",
  };
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

  const location = body.profile?.location ?? body.locationContext ?? "not provided";
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

export async function generateRecipeWithOpenAI(
  body: BackendRecipeGenerateRequest
): Promise<Recipe> {
  const { apiKey, baseURL, model } = getOpenAIConfig();
  const url = new URL("v1/chat/completions", baseURL).toString();

  const userPrompt = buildUserPrompt(body);

  const requestBody = {
    model,
    messages: [
      {
        role: "system",
        content:
          "You are a recipe assistant. Return only strict JSON that follows the provided schema. No markdown, no extra text.",
      },
      { role: "user", content: userPrompt },
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
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(requestBody),
  });

  const text = await resp.text();
  if (!resp.ok) {
    let message = `OpenAI error (${resp.status})`;
    try {
      const json = JSON.parse(text) as any;
      message = json?.error?.message ? `OpenAI error (${resp.status}): ${json.error.message}` : message;
    } catch {
      // ignore parse errors
    }
    throw new Error(message);
  }

  let completion: OpenAIChatCompletionResponse;
  try {
    completion = JSON.parse(text) as OpenAIChatCompletionResponse;
  } catch {
    throw new Error("OpenAI returned non-JSON response");
  }

  const content = completion.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI response missing message content");

  try {
    return JSON.parse(content) as Recipe;
  } catch {
    throw new Error("OpenAI returned invalid JSON recipe payload");
  }
}

