import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const PEXELS_API_KEY = Deno.env.get("PEXELS_API_KEY");

/**
 * CircleVeya-Logo als Fallback, wenn Groq/Pexels fehlschlagen oder nichts liefern.
 * Bei Bedarf durch eine öffentliche Storage-/CDN-URL ersetzen.
 */
const FALLBACK_LOGO_URL =
  "https://circleveya.vercel.app/assets/assets/branding/circleveya_logo.png";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.1-8b-instant";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

/** Einfacher Fallback ohne KI, falls Groq nicht erreichbar ist. */
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

async function extractKeywordWithGroq(
  activityName: string,
): Promise<{ keyword: string; source: "groq" | "heuristic" }> {
  if (!GROQ_API_KEY) {
    console.warn("fetch-activity-image: GROQ_API_KEY fehlt – Heuristik");
    return { keyword: heuristicKeyword(activityName), source: "heuristic" };
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8_000);

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

    if (!res.ok) {
      const errBody = await res.text().catch(() => "");
      console.error(
        "fetch-activity-image: Groq HTTP",
        res.status,
        errBody.slice(0, 300),
      );
      return { keyword: heuristicKeyword(activityName), source: "heuristic" };
    }

    const data = await res.json();
    const content = data?.choices?.[0]?.message?.content;
    const keyword =
      typeof content === "string" ? sanitizeKeyword(content) : "";

    if (!keyword) {
      console.warn("fetch-activity-image: Groq leere Antwort – Heuristik");
      return { keyword: heuristicKeyword(activityName), source: "heuristic" };
    }

    console.log("fetch-activity-image: Groq keyword:", keyword);
    return { keyword, source: "groq" };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("fetch-activity-image: Groq exception", message);
    return { keyword: heuristicKeyword(activityName), source: "heuristic" };
  }
}

async function searchPexels(
  query: string,
): Promise<{
  imageUrl: string | null;
  photographer: string | null;
  error?: string;
}> {
  if (!PEXELS_API_KEY) {
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
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);

    const res = await fetch(
      `https://api.pexels.com/v1/search?${params.toString()}`,
      {
        signal: controller.signal,
        headers: { Authorization: PEXELS_API_KEY },
      },
    );
    clearTimeout(timeout);

    if (!res.ok) {
      const errBody = await res.text().catch(() => "");
      console.error(
        "fetch-activity-image: Pexels HTTP",
        res.status,
        errBody.slice(0, 300),
      );
      return {
        imageUrl: null,
        photographer: null,
        error: `Pexels ${res.status}`,
      };
    }

    const data = await res.json();
    const photos = Array.isArray(data?.photos) ? data.photos : [];
    const chosen = pickRandom(photos as Array<Record<string, unknown>>);
    const src = chosen?.src as Record<string, unknown> | undefined;
    const imageUrl =
      (typeof src?.large === "string" ? src.large : null) ??
      (typeof src?.landscape === "string" ? src.landscape : null) ??
      (typeof src?.medium === "string" ? src.medium : null);

    return {
      imageUrl,
      photographer:
        typeof chosen?.photographer === "string" ? chosen.photographer : null,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("fetch-activity-image: Pexels exception", message);
    return { imageUrl: null, photographer: null, error: message };
  }
}

function fallbackPayload(
  activityName: string,
  extras: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    image_url: FALLBACK_LOGO_URL,
    fallback: true,
    fallback_logo_url: FALLBACK_LOGO_URL,
    activityName,
    ...extras,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Immer 200 mit image_url – die App soll bei API-Fehlern nicht abstürzen.
  try {
    let body: Record<string, unknown> = {};
    try {
      body = (await req.json()) as Record<string, unknown>;
    } catch {
      console.warn("fetch-activity-image: Body kein JSON");
      return jsonResponse(
        fallbackPayload("", { error: "Ungültiger Request-Body" }),
      );
    }

    const activityName =
      typeof body.activityName === "string"
        ? body.activityName.trim()
        : typeof body.title === "string"
          ? body.title.trim()
          : "";

    if (!activityName) {
      return jsonResponse(
        fallbackPayload("", { error: "activityName erforderlich" }),
      );
    }

    console.log("fetch-activity-image: activityName=", activityName);

    const { keyword, source: keywordSource } =
      await extractKeywordWithGroq(activityName);

    const pexels = await searchPexels(keyword);

    if (pexels.imageUrl) {
      console.log("fetch-activity-image: success", pexels.imageUrl);
      return jsonResponse({
        image_url: pexels.imageUrl,
        fallback: false,
        query: keyword,
        keyword_source: keywordSource,
        photographer: pexels.photographer,
        activityName,
      });
    }

    console.warn(
      "fetch-activity-image: kein Pexels-Treffer – Logo-Fallback",
      pexels.error ?? "",
    );
    return jsonResponse(
      fallbackPayload(activityName, {
        query: keyword,
        keyword_source: keywordSource,
        error: pexels.error ?? "Kein passendes Bild gefunden",
      }),
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("fetch-activity-image: unhandled", message);
    return jsonResponse(
      fallbackPayload("", { error: message }),
    );
  }
});
