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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!PEXELS_API_KEY) {
      return jsonResponse({ error: "PEXELS_API_KEY ist nicht gesetzt" }, 500);
    }

    const body = await req.json();
    const activityName =
      typeof body?.activityName === "string"
        ? body.activityName.trim()
        : typeof body?.title === "string"
          ? body.title.trim()
          : "";

    if (!activityName) {
      return jsonResponse({ error: "activityName erforderlich" }, 400);
    }

    // Relevantere Treffer: Aktivitätsname + sport action, Querformat, 5 Kandidaten
    const query = `${activityName} sport action`;
    const params = new URLSearchParams({
      query,
      orientation: "landscape",
      per_page: "5",
    });

    const pexelsRes = await fetch(
      `https://api.pexels.com/v1/search?${params.toString()}`,
      {
        headers: { Authorization: Deno.env.get("PEXELS_API_KEY")! },
      },
    );

    if (!pexelsRes.ok) {
      return jsonResponse(
        { error: `Pexels API Fehler: ${pexelsRes.status}` },
        502,
      );
    }

    const pexelsData = await pexelsRes.json();
    const photos = Array.isArray(pexelsData?.photos) ? pexelsData.photos : [];
    const chosen = pickRandom(photos);
    const imageUrl =
      chosen?.src?.large ??
      chosen?.src?.landscape ??
      chosen?.src?.medium ??
      null;

    if (!imageUrl || typeof imageUrl !== "string") {
      return jsonResponse({ error: "Kein passendes Bild gefunden" }, 404);
    }

    return jsonResponse({
      image_url: imageUrl,
      query,
      photographer: chosen?.photographer ?? null,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return jsonResponse({ error: message }, 500);
  }
});
