import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const PEXELS_API_KEY = Deno.env.get("PEXELS_API_KEY");

/**
 * CircleVeya-Emblem als Fallback, wenn Groq/Pexels fehlschlagen oder nichts liefern.
 * Bei Bedarf durch eine öffentliche Storage-/CDN-URL ersetzen.
 */
const FALLBACK_EMBLEM_URL =
  "https://circleveya.vercel.app/assets/assets/branding/circleveya_emblem.png";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.1-8b-instant";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/** Nur Prefix – nie den vollen Key loggen. */
function keyStatus(name: string, value: string | undefined): string {
  if (!value) return `${name}=FEHLT`;
  const prefix = value.length >= 4 ? value.slice(0, 4) : "????";
  return `${name}=gesetzt (len=${value.length}, prefix=${prefix}…)`;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function pickRandom<T>(items: T[]): T | undefined {
  if (items.length === 0) return undefined;
  return items[Math.floor(Math.random() * items.length)];
}

function sanitizeKeyword(raw: string): string {
  return raw
    .replace(/^["'`]+|["'`]+$/g, "")
    .replace(/[^\p{L}\p{N}\s-]/gu, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 80);
}

function heuristicKeyword(activityName: string): string {
  const stop = new Set([
    "mit",
    "und",
    "im",
    "in",
    "am",
    "an",
    "auf",
    "bei",
    "zum",
    "zur",
    "der",
    "die",
    "das",
    "ein",
    "eine",
    "einen",
    "dem",
    "den",
    "des",
    "für",
    "von",
    "vom",
    "nach",
    "heute",
    "morgen",
    "abend",
    "the",
    "a",
    "an",
    "and",
    "with",
    "for",
  ]);
  const tokens = activityName
    .toLowerCase()
    .split(/[\s,/|+-]+/)
    .map((t) => t.replace(/[^\p{L}\p{N}-]/gu, ""))
    .filter((t) => t.length > 2 && !stop.has(t));
  return tokens.slice(0, 3).join(" ") || "friends outdoor activity";
}

function fallbackPayload(
  activityName: string,
  extras: Record<string, unknown> = {},
): Record<string, unknown> {
  console.log("Using FALLBACK_EMBLEM_URL:", FALLBACK_EMBLEM_URL);
  return {
    image_url: FALLBACK_EMBLEM_URL,
    fallback: true,
    fallback_emblem_url: FALLBACK_EMBLEM_URL,
    activityName,
    ...extras,
  };
}

async function extractKeywordWithGroq(
  activityName: string,
): Promise<{ keyword: string; source: "groq" | "heuristic" }> {
  console.log("Groq: start keyword extraction for:", activityName);

  if (!GROQ_API_KEY) {
    console.error("catch/env: GROQ_API_KEY is not loaded");
    const keyword = heuristicKeyword(activityName);
    console.log("Extracted Keyword:", keyword);
    console.log("Keyword source: heuristic (no GROQ_API_KEY)");
    return { keyword, source: "heuristic" };
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8_000);

    console.log("Groq: POST", GROQ_URL, "model=", GROQ_MODEL);
    const res = await fetch(GROQ_URL, {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.2,
        max_tokens: 24,
        messages: [
          {
            role: "system",
            content:
              "You extract a short English stock-photo search query (1-4 words) " +
              "for Pexels from an activity title. Reply with ONLY the query words. " +
              "No quotes, no punctuation, no explanation. Prefer concrete visual " +
              "subjects (e.g. hiking mountains, soccer match, coffee cafe).",
          },
          {
            role: "user",
            content: activityName,
          },
        ],
      }),
    });

    clearTimeout(timeout);

    const groqText = await res.text();
    console.log("Groq Status:", res.status);
    console.log("Groq Response:", groqText.slice(0, 1500));

    if (!res.ok) {
      console.error("catch/http: Groq request failed with status", res.status);
      const keyword = heuristicKeyword(activityName);
      console.log("Extracted Keyword:", keyword);
      console.log("Keyword source: heuristic (Groq HTTP error)");
      return { keyword, source: "heuristic" };
    }

    let data: Record<string, unknown>;
    try {
      data = JSON.parse(groqText) as Record<string, unknown>;
    } catch (parseErr) {
      console.error("catch: Groq JSON parse failed", parseErr);
      const keyword = heuristicKeyword(activityName);
      console.log("Extracted Keyword:", keyword);
      console.log("Keyword source: heuristic (Groq parse error)");
      return { keyword, source: "heuristic" };
    }

    const choices = data?.choices;
    const first = Array.isArray(choices) ? choices[0] : undefined;
    const message = (first as Record<string, unknown> | undefined)?.message;
    const content = (message as Record<string, unknown> | undefined)?.content;
    const keyword =
      typeof content === "string" ? sanitizeKeyword(content) : "";

    if (!keyword) {
      console.warn("Groq returned empty keyword – using heuristic");
      const fallbackKeyword = heuristicKeyword(activityName);
      console.log("Extracted Keyword:", fallbackKeyword);
      console.log("Keyword source: heuristic (empty Groq content)");
      return { keyword: fallbackKeyword, source: "heuristic" };
    }

    console.log("Extracted Keyword:", keyword);
    console.log("Keyword source: groq");
    return { keyword, source: "groq" };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("catch: Groq exception", message);
    const keyword = heuristicKeyword(activityName);
    console.log("Extracted Keyword:", keyword);
    console.log("Keyword source: heuristic (Groq exception)");
    return { keyword, source: "heuristic" };
  }
}

async function searchPexels(
  query: string,
): Promise<{
  imageUrl: string | null;
  photographer: string | null;
  error?: string;
  status?: number;
}> {
  console.log("Pexels: start search for query:", query);

  if (!PEXELS_API_KEY) {
    console.error("catch/env: PEXELS_API_KEY is not loaded");
    return {
      imageUrl: null,
      photographer: null,
      error: "PEXELS_API_KEY fehlt",
    };
  }

  try {
    const params = new URLSearchParams({
      query,
      orientation: "landscape",
      per_page: "8",
    });
    const pexelsUrl = `https://api.pexels.com/v1/search?${params.toString()}`;
    console.log("Pexels URL:", pexelsUrl);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);

    const pexelsResponse = await fetch(pexelsUrl, {
      signal: controller.signal,
      headers: { Authorization: PEXELS_API_KEY },
    });
    clearTimeout(timeout);

    const responseText = await pexelsResponse.text();
    console.log("Pexels Status:", pexelsResponse.status);
    console.log("Pexels Response:", responseText.slice(0, 2000));

    if (!pexelsResponse.ok) {
      console.error(
        "catch/http: Pexels request failed with status",
        pexelsResponse.status,
      );
      return {
        imageUrl: null,
        photographer: null,
        error: `Pexels ${pexelsResponse.status}`,
        status: pexelsResponse.status,
      };
    }

    let data: Record<string, unknown>;
    try {
      data = JSON.parse(responseText) as Record<string, unknown>;
    } catch (parseErr) {
      console.error("catch: Pexels JSON parse failed", parseErr);
      return {
        imageUrl: null,
        photographer: null,
        error: "Pexels JSON parse failed",
        status: pexelsResponse.status,
      };
    }

    const photos = Array.isArray(data?.photos) ? data.photos : [];
    console.log("Pexels photos count:", photos.length);

    const chosen = pickRandom(photos as Array<Record<string, unknown>>);
    const src = chosen?.src as Record<string, unknown> | undefined;
    const imageUrl =
      (typeof src?.large === "string" ? src.large : null) ??
      (typeof src?.landscape === "string" ? src.landscape : null) ??
      (typeof src?.medium === "string" ? src.medium : null);

    console.log("Pexels chosen image_url:", imageUrl ?? "(none)");

    return {
      imageUrl,
      photographer:
        typeof chosen?.photographer === "string" ? chosen.photographer : null,
      status: pexelsResponse.status,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("catch: Pexels exception", message);
    return { imageUrl: null, photographer: null, error: message };
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  console.log("=== fetch-activity-image START ===");
  console.log("Env check:", keyStatus("GROQ_API_KEY", GROQ_API_KEY));
  console.log("Env check:", keyStatus("PEXELS_API_KEY", PEXELS_API_KEY));

  // Immer 200 + image_url – nie einen Fehler werfen, der die App crashen lässt.
  try {
    let body: Record<string, unknown> = {};
    try {
      body = (await req.json()) as Record<string, unknown>;
      console.log("Request body:", JSON.stringify(body));
    } catch (parseErr) {
      console.error("catch: Request body is not JSON", parseErr);
      return jsonResponse(
        fallbackPayload("", {
          error: "Ungültiger Request-Body",
          debug: {
            groq_key_loaded: Boolean(GROQ_API_KEY),
            pexels_key_loaded: Boolean(PEXELS_API_KEY),
          },
        }),
      );
    }

    const activityName =
      typeof body.activityName === "string"
        ? body.activityName.trim()
        : typeof body.title === "string"
          ? body.title.trim()
          : "";

    if (!activityName) {
      console.warn("activityName missing – returning fallback");
      return jsonResponse(
        fallbackPayload("", {
          error: "activityName erforderlich",
          debug: {
            groq_key_loaded: Boolean(GROQ_API_KEY),
            pexels_key_loaded: Boolean(PEXELS_API_KEY),
          },
        }),
      );
    }

    console.log("activityName:", activityName);

    const { keyword, source: keywordSource } =
      await extractKeywordWithGroq(activityName);

    const pexels = await searchPexels(keyword);

    if (pexels.imageUrl) {
      console.log("SUCCESS image_url:", pexels.imageUrl);
      console.log("=== fetch-activity-image END (pexels) ===");
      return jsonResponse({
        image_url: pexels.imageUrl,
        fallback: false,
        query: keyword,
        keyword_source: keywordSource,
        photographer: pexels.photographer,
        activityName,
        debug: {
          groq_key_loaded: Boolean(GROQ_API_KEY),
          pexels_key_loaded: Boolean(PEXELS_API_KEY),
          pexels_status: pexels.status ?? null,
        },
      });
    }

    console.warn(
      "No Pexels image – returning emblem fallback. reason:",
      pexels.error ?? "empty photos",
    );
    console.log("=== fetch-activity-image END (fallback) ===");
    return jsonResponse(
      fallbackPayload(activityName, {
        query: keyword,
        keyword_source: keywordSource,
        error: pexels.error ?? "Kein passendes Bild gefunden",
        debug: {
          groq_key_loaded: Boolean(GROQ_API_KEY),
          pexels_key_loaded: Boolean(PEXELS_API_KEY),
          pexels_status: pexels.status ?? null,
        },
      }),
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("catch: unhandled top-level exception", message);
    console.log("=== fetch-activity-image END (unhandled fallback) ===");
    return jsonResponse(
      fallbackPayload("", {
        error: message,
        debug: {
          groq_key_loaded: Boolean(GROQ_API_KEY),
          pexels_key_loaded: Boolean(PEXELS_API_KEY),
        },
      }),
    );
  }
});
