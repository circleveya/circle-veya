import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GIPHY_API_KEY = Deno.env.get("GIPHY_API_KEY")?.trim();

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

type GifItem = {
  id: string;
  url: string;
  preview_url: string;
};

const FALLBACK: GifItem[] = [
  {
    id: "3o7abKhOpu0NwenH3O",
    url: "https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif",
    preview_url: "https://media.giphy.com/media/3o7abKhOpu0NwenH3O/200w.gif",
  },
  {
    id: "5GoVLqeAOo6PK",
    url: "https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif",
    preview_url: "https://media.giphy.com/media/5GoVLqeAOo6PK/200w.gif",
  },
  {
    id: "111ebonMs90YLu",
    url: "https://media.giphy.com/media/111ebonMs90YLu/giphy.gif",
    preview_url: "https://media.giphy.com/media/111ebonMs90YLu/200w.gif",
  },
  {
    id: "3o6Zt481isNVuQI1l6",
    url: "https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif",
    preview_url: "https://media.giphy.com/media/3o6Zt481isNVuQI1l6/200w.gif",
  },
  {
    id: "l0MYC0LajbaPoEADe",
    url: "https://media.giphy.com/media/l0MYC0LajbaPoEADe/giphy.gif",
    preview_url: "https://media.giphy.com/media/l0MYC0LajbaPoEADe/200w.gif",
  },
  {
    id: "26ufdipQqU2lhNA4g",
    url: "https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif",
    preview_url: "https://media.giphy.com/media/26ufdipQqU2lhNA4g/200w.gif",
  },
  {
    id: "l3q2K5jinAlChoCLS",
    url: "https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif",
    preview_url: "https://media.giphy.com/media/l3q2K5jinAlChoCLS/200w.gif",
  },
  {
    id: "IsDjNJl8oXa1y",
    url: "https://media.giphy.com/media/IsDjNJl8oXa1y/giphy.gif",
    preview_url: "https://media.giphy.com/media/IsDjNJl8oXa1y/200w.gif",
  },
  {
    id: "13HgwGsXF0aiGY",
    url: "https://media.giphy.com/media/13HgwGsXF0aiGY/giphy.gif",
    preview_url: "https://media.giphy.com/media/13HgwGsXF0aiGY/200w.gif",
  },
  {
    id: "3oEjHCWdU7F4hqVQYg",
    url: "https://media.giphy.com/media/3oEjHCWdU7F4hqVQYg/giphy.gif",
    preview_url: "https://media.giphy.com/media/3oEjHCWdU7F4hqVQYg/200w.gif",
  },
  {
    id: "l0MYGbFj9fLTVXbR6",
    url: "https://media.giphy.com/media/l0MYGbFj9fLTVXbR6/giphy.gif",
    preview_url: "https://media.giphy.com/media/l0MYGbFj9fLTVXbR6/200w.gif",
  },
  {
    id: "l0HlPystfePnAI3Q4",
    url: "https://media.giphy.com/media/l0HlPystfePnAI3Q4/giphy.gif",
    preview_url: "https://media.giphy.com/media/l0HlPystfePnAI3Q4/200w.gif",
  },
];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const query = typeof body?.query === "string" ? body.query.trim() : "";
    const limit = Math.min(
      Math.max(Number(body?.limit) || 24, 1),
      48,
    );

    if (!GIPHY_API_KEY) {
      return jsonResponse({ gifs: FALLBACK.slice(0, limit), source: "fallback" });
    }

    const endpoint = query
      ? `https://api.giphy.com/v1/gifs/search?api_key=${
        encodeURIComponent(GIPHY_API_KEY)
      }&q=${encodeURIComponent(query)}&limit=${limit}&rating=pg-13&lang=de`
      : `https://api.giphy.com/v1/gifs/trending?api_key=${
        encodeURIComponent(GIPHY_API_KEY)
      }&limit=${limit}&rating=pg-13`;

    const res = await fetch(endpoint);
    if (!res.ok) {
      return jsonResponse({
        gifs: FALLBACK.slice(0, limit),
        source: "fallback",
        error: `giphy_${res.status}`,
      });
    }

    const data = await res.json();
    const gifs: GifItem[] = [];
    for (const item of data?.data ?? []) {
      const id = item?.id;
      const url = item?.images?.downsized_medium?.url ??
        item?.images?.original?.url;
      const preview = item?.images?.fixed_width_small?.url ??
        item?.images?.preview_gif?.url ??
        url;
      if (!id || !url) continue;
      gifs.push({ id: String(id), url: String(url), preview_url: String(preview) });
    }

    return jsonResponse({
      gifs: gifs.length > 0 ? gifs : FALLBACK.slice(0, limit),
      source: gifs.length > 0 ? "giphy" : "fallback",
    });
  } catch (error) {
    return jsonResponse(
      {
        gifs: FALLBACK,
        source: "fallback",
        error: error instanceof Error ? error.message : "unknown",
      },
      200,
    );
  }
});
