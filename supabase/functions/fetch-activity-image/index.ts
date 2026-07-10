import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const PEXELS_API_KEY = Deno.env.get("PEXELS_API_KEY");

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
  const index = Math.floor(Math.random() * items.length);
  return items[index];
}

function keyPrefix(key: string | undefined): string {
  if (!key) return "(nicht gesetzt)";
  if (key.length <= 4) return `${key}…`;
  return `${key.slice(0, 4)}…`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("fetch-activity-image: Request", req.method);
    console.log(
      "fetch-activity-image: PEXELS_API_KEY prefix:",
      keyPrefix(PEXELS_API_KEY),
    );

    if (!PEXELS_API_KEY) {
      console.error("fetch-activity-image: PEXELS_API_KEY fehlt");
      return jsonResponse({ error: "PEXELS_API_KEY ist nicht gesetzt" }, 500);
    }

    const body = await req.json();
    console.log("fetch-activity-image: Body", JSON.stringify(body));

    const activityName =
      typeof body?.activityName === "string"
        ? body.activityName.trim()
        : typeof body?.title === "string"
          ? body.title.trim()
          : "";

    if (!activityName) {
      console.warn("fetch-activity-image: activityName fehlt");
      return jsonResponse({ error: "activityName erforderlich" }, 400);
    }

    // DEBUG: statische Test-Query, um Key/Netzwerk von Query-Problemen zu trennen.
    // TODO: wieder auf `${activityName} sport action` zurückstellen.
    const query = "nature";
    console.log(
      "fetch-activity-image: DEBUG query='nature' (activityName war:",
      activityName,
      ")",
    );

    const params = new URLSearchParams({
      query,
      orientation: "landscape",
      per_page: "5",
    });
    const pexelsUrl = `https://api.pexels.com/v1/search?${params.toString()}`;
    console.log("fetch-activity-image: Pexels URL", pexelsUrl);

    const pexelsRes = await fetch(pexelsUrl, {
      headers: { Authorization: Deno.env.get("PEXELS_API_KEY")! },
    });

    console.log("Status:", pexelsRes.status);
    const responseText = await pexelsRes.text();
    console.log("Antwort:", responseText);

    if (!pexelsRes.ok) {
      return jsonResponse(
        {
          error: `Pexels API Fehler: ${pexelsRes.status}`,
          pexels_body: responseText.slice(0, 500),
        },
        502,
      );
    }

    let pexelsData: Record<string, unknown>;
    try {
      pexelsData = JSON.parse(responseText) as Record<string, unknown>;
    } catch (parseError) {
      console.error("fetch-activity-image: JSON parse failed", parseError);
      return jsonResponse(
        { error: "Pexels Antwort ist kein gültiges JSON" },
        502,
      );
    }

    const photos = Array.isArray(pexelsData?.photos) ? pexelsData.photos : [];
    console.log("fetch-activity-image: photos count", photos.length);

    const chosen = pickRandom(photos as Array<Record<string, unknown>>);
    const src = chosen?.src as Record<string, unknown> | undefined;
    const imageUrl =
      (typeof src?.large === "string" ? src.large : null) ??
      (typeof src?.landscape === "string" ? src.landscape : null) ??
      (typeof src?.medium === "string" ? src.medium : null);

    if (!imageUrl) {
      console.warn("fetch-activity-image: keine imageUrl in photos");
      return jsonResponse({ error: "Kein passendes Bild gefunden" }, 404);
    }

    console.log("fetch-activity-image: success", imageUrl);
    return jsonResponse({
      image_url: imageUrl,
      query,
      photographer:
        typeof chosen?.photographer === "string" ? chosen.photographer : null,
      debug_key_prefix: keyPrefix(PEXELS_API_KEY),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("fetch-activity-image: exception", message);
    return jsonResponse({ error: message }, 500);
  }
});
