import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PEXELS_API_KEY = Deno.env.get("PEXELS_API_KEY");

const DEFAULT_FALLBACK_IMAGE =
  "https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg";

// Schweizer Standard-Aktivitäten → englische Pexels-Suchbegriffe
const keywordTranslation: Record<string, string> = {
  fussball: "soccer",
  fußball: "soccer",
  joggen: "running",
  laufen: "running",
  kaffee: "coffee",
  gaming: "gaming",
  zocken: "gaming",
  wandern: "hiking",
  biken: "cycling",
  motorrad: "motorcycle",
  yoga: "yoga",
  essen: "food",
  kochen: "cooking",
  party: "party",
  segeln: "sailing",
};

function extractSearchTerm(title: string): string {
  const cleanTitle = title.toLowerCase().trim();

  for (const [key, value] of Object.entries(keywordTranslation)) {
    if (cleanTitle.includes(key)) return value;
  }

  const stopWords = [
    "mit",
    "und",
    "im",
    "in",
    "ein",
    "eine",
    "für",
    "gehen",
    "spielen",
  ];
  const words = cleanTitle
    .split(/\s+/)
    .filter((w) => !stopWords.includes(w) && w.length > 2);

  return words.length > 0 ? words[0] : "activity";
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const record = body.record ?? body;

    if (!record?.id || !record?.title) {
      return new Response(
        JSON.stringify({ error: "record.id und record.title erforderlich" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        },
      );
    }

    if (record.image_url) {
      return new Response(
        JSON.stringify({ message: "Bild bereits vorhanden." }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        },
      );
    }

    if (!PEXELS_API_KEY) {
      throw new Error("PEXELS_API_KEY ist nicht gesetzt");
    }

    const searchTerm = extractSearchTerm(record.title);

    const pexelsRes = await fetch(
      `https://api.pexels.com/v1/search?query=${encodeURIComponent(searchTerm)}&per_page=1`,
      {
        headers: { Authorization: PEXELS_API_KEY },
      },
    );

    if (!pexelsRes.ok) {
      throw new Error(`Pexels API Fehler: ${pexelsRes.status}`);
    }

    const pexelsData = await pexelsRes.json();
    let finalImageUrl: string | null =
      pexelsData.photos?.[0]?.src?.large ?? null;
    let imageSource = "pexels";

    if (!finalImageUrl) {
      finalImageUrl = DEFAULT_FALLBACK_IMAGE;
      imageSource = "fallback";
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { error } = await supabaseClient
      .from("activities")
      .update({ image_url: finalImageUrl })
      .eq("id", record.id);

    if (error) throw error;

    return new Response(
      JSON.stringify({
        success: true,
        imageUrl: finalImageUrl,
        searchTerm,
        imageSource,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
