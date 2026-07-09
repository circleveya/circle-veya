import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EVENTBRITE_API_KEY = Deno.env.get("EVENTBRITE_API_KEY");
const TICKETMASTER_API_KEY = Deno.env.get("TICKETMASTER_API_KEY");

const DEFAULT_RADIUS_KM = 50;

/** Schweizer Städte – Fallback für Cron-Sync ohne Request-Body */
const SWISS_LOCATIONS = [
  { label: "Zürich", lat: 47.3769, lng: 8.5417 },
  { label: "Bern", lat: 46.948, lng: 7.4474 },
  { label: "Basel", lat: 47.5596, lng: 7.5886 },
  { label: "Frauenfeld", lat: 47.5569, lng: 8.8982 },
  { label: "Genf", lat: 46.2044, lng: 6.1432 },
  { label: "Lausanne", lat: 46.5197, lng: 6.6323 },
  { label: "Luzern", lat: 47.0505, lng: 8.3055 },
  { label: "Winterthur", lat: 47.5, lng: 8.75 },
  { label: "St. Gallen", lat: 47.4245, lng: 9.3767 },
  { label: "Lugano", lat: 46.0037, lng: 8.9511 },
];

type GeoQuery = {
  label: string;
  lat: number;
  lng: number;
  radiusKm: number;
  countryCode: string;
};

type NormalizedEvent = {
  external_id: string;
  external_provider: string;
  title: string;
  description: string | null;
  date_time: string | null;
  location_name: string | null;
  latitude: number | null;
  longitude: number | null;
  image_url: string | null;
  external_url: string;
  location_type: "indoor" | "outdoor";
};

type SyncRequestBody = {
  lat?: number;
  lng?: number;
  radius_km?: number;
  country_code?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/** Ticketmaster latlong: "47.5586,8.8901" (Breite,Länge – Komma, Punkt-Dezimal) */
function formatLatLong(lat: number, lng: number): string {
  const safeLat = Number(lat.toFixed(4));
  const safeLng = Number(lng.toFixed(4));
  return `${safeLat},${safeLng}`;
}

function clampRadiusKm(radiusKm: number): number {
  if (!Number.isFinite(radiusKm) || radiusKm <= 0) return DEFAULT_RADIUS_KM;
  return Math.min(200, Math.max(1, Math.round(radiusKm)));
}

/** Grobe CH-Bounding-Box für countryCode=CH */
function isInSwitzerland(lat: number, lng: number): boolean {
  return lat >= 45.7 && lat <= 47.9 && lng >= 5.8 && lng <= 10.6;
}

function resolveCountryCode(lat: number, lng: number, explicit?: string): string {
  if (explicit && explicit.trim().length === 2) {
    return explicit.trim().toUpperCase();
  }
  return isInSwitzerland(lat, lng) ? "CH" : "CH";
}

function inferLocationType(title: string): "indoor" | "outdoor" {
  const lower = title.toLowerCase();
  const indoor = [
    "konzert",
    "concert",
    "theater",
    "museum",
    "club",
    "indoor",
    "halle",
    "arena",
    "kino",
    "comedy",
  ];
  return indoor.some((k) => lower.includes(k)) ? "indoor" : "outdoor";
}

function isFutureOrUnset(dateTime: string | null): boolean {
  if (!dateTime) return true;
  const parsed = Date.parse(dateTime);
  if (Number.isNaN(parsed)) return true;
  return parsed > Date.now();
}


async function readSyncRequestBody(req: Request): Promise<SyncRequestBody | null> {
  if (req.method !== "POST") return null;
  const contentType = req.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return null;
  try {
    const body = await req.json();
    if (!body || typeof body !== "object") return null;
    return body as SyncRequestBody;
  } catch {
    return null;
  }
}

function buildGeoQueriesFromBody(body: SyncRequestBody | null): GeoQuery[] {
  if (
    body?.lat != null &&
    body?.lng != null &&
    Number.isFinite(body.lat) &&
    Number.isFinite(body.lng)
  ) {
    const lat = Number(body.lat);
    const lng = Number(body.lng);
    const radiusKm = clampRadiusKm(Number(body.radius_km ?? DEFAULT_RADIUS_KM));
    const countryCode = resolveCountryCode(lat, lng, body.country_code);

    return [
      {
        label: `GPS ${formatLatLong(lat, lng)}`,
        lat,
        lng,
        radiusKm,
        countryCode,
      },
    ];
  }

  return SWISS_LOCATIONS.map((loc) => ({
    ...loc,
    radiusKm: DEFAULT_RADIUS_KM,
    countryCode: "CH",
  }));
}

async function fetchEventbriteEvents(
  location: GeoQuery,
): Promise<NormalizedEvent[]> {
  if (!EVENTBRITE_API_KEY) return [];

  const radius = clampRadiusKm(location.radiusKm);
  const url =
    `https://www.eventbriteapi.com/v3/events/search/?` +
    `location.address=${encodeURIComponent(location.label + ", Switzerland")}` +
    `&location.within=${radius}km&expand=venue&page=1&sort_by=date`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${EVENTBRITE_API_KEY}` },
  });

  if (!res.ok) {
    console.error("Eventbrite error", location.label, res.status, await res.text());
    return [];
  }

  const data = await res.json();
  const events = data.events ?? [];

  return events
    .map((event: Record<string, unknown>) => {
      const venue = event.venue as Record<string, unknown> | undefined;
      const logo = event.logo as Record<string, unknown> | undefined;
      const name = event.name as Record<string, string> | undefined;
      const desc = event.description as Record<string, string> | undefined;
      const start = event.start as Record<string, string> | undefined;
      const title = (name?.text ?? "Event").slice(0, 120);

      return {
        external_id: String(event.id),
        external_provider: "eventbrite",
        title,
        description: desc?.text?.slice(0, 500) ?? null,
        date_time: start?.utc ?? null,
        location_name: (venue?.name as string) ?? location.label,
        latitude: venue?.latitude
          ? parseFloat(String(venue.latitude))
          : location.lat,
        longitude: venue?.longitude
          ? parseFloat(String(venue.longitude))
          : location.lng,
        image_url: (logo?.url as string) ?? null,
        external_url: String(event.url ?? ""),
        location_type: inferLocationType(title),
      };
    })
    .filter((e: NormalizedEvent) =>
      e.external_url.length > 0 && isFutureOrUnset(e.date_time)
    );
}

async function fetchTicketmasterEvents(
  location: GeoQuery,
): Promise<NormalizedEvent[]> {
  if (!TICKETMASTER_API_KEY) return [];

  const radiusKm = clampRadiusKm(location.radiusKm);
  const latlong = formatLatLong(location.lat, location.lng);
  const countryCode = resolveCountryCode(
    location.lat,
    location.lng,
    location.countryCode,
  );

  const params = new URLSearchParams({
    apikey: TICKETMASTER_API_KEY,
    latlong,
    radius: String(radiusKm),
    unit: "km",
    countryCode,
    size: "20",
    sort: "date,asc",
  });

  const url =
    `https://app.ticketmaster.com/discovery/v2/events.json?${params.toString()}`;

  console.log(
    "Ticketmaster request",
    location.label,
    `latlong=${latlong}`,
    `radius=${radiusKm}`,
    `unit=km`,
    `countryCode=${countryCode}`,
  );

  const res = await fetch(url);
  if (!res.ok) {
    console.error(
      "Ticketmaster error",
      location.label,
      res.status,
      await res.text(),
    );
    return [];
  }

  const data = await res.json();
  const events = data._embedded?.events ?? [];

  return events
    .map((event: Record<string, unknown>) => {
      const venues = (event._embedded as Record<string, unknown>)?.venues as
        | Record<string, unknown>[]
        | undefined;
      const venue = venues?.[0];
      const loc = venue?.location as Record<string, string> | undefined;
      const images = event.images as Record<string, unknown>[] | undefined;
      const image = images?.find((i) => i.ratio === "16_9") ?? images?.[0];
      const dates = event.dates as Record<string, unknown> | undefined;
      const start = dates?.start as Record<string, string> | undefined;
      const title = String(event.name ?? "Event").slice(0, 120);

      return {
        external_id: String(event.id),
        external_provider: "ticketmaster",
        title,
        description: null,
        date_time: start?.dateTime ?? null,
        location_name: (venue?.name as string) ?? location.label,
        latitude: loc?.latitude ? parseFloat(loc.latitude) : location.lat,
        longitude: loc?.longitude ? parseFloat(loc.longitude) : location.lng,
        image_url: (image?.url as string) ?? null,
        external_url: String(event.url ?? ""),
        location_type: inferLocationType(title),
      };
    })
    .filter((e: NormalizedEvent) =>
      e.external_url.length > 0 && isFutureOrUnset(e.date_time)
    );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startedAt = new Date().toISOString();
  const providers: string[] = [];
  if (EVENTBRITE_API_KEY) providers.push("eventbrite");
  if (TICKETMASTER_API_KEY) providers.push("ticketmaster");

  try {
    if (providers.length === 0) {
      throw new Error(
        "Kein API-Key gesetzt. Mindestens EVENTBRITE_API_KEY oder TICKETMASTER_API_KEY erforderlich.",
      );
    }

    const body = await readSyncRequestBody(req);
    const geoQueries = buildGeoQueriesFromBody(body);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: hostId, error: hostError } = await supabase.rpc(
      "get_external_events_host_id",
    );

    if (hostError || !hostId) {
      throw new Error(
        "System-Host circle_events nicht gefunden. Siehe supabase/setup_external_events_host.sql",
      );
    }

    const allEvents: NormalizedEvent[] = [];

    for (const loc of geoQueries) {
      const [eb, tm] = await Promise.all([
        fetchEventbriteEvents(loc),
        fetchTicketmasterEvents(loc),
      ]);
      allEvents.push(...eb, ...tm);
    }

    const unique = new Map<string, NormalizedEvent>();
    for (const e of allEvents) {
      unique.set(`${e.external_provider}:${e.external_id}`, e);
    }

    let inserted = 0;
    let updated = 0;
    const errors: string[] = [];

    for (const event of unique.values()) {
      const payload: Record<string, unknown> = {
        host_id: hostId,
        title: event.title,
        description: event.description,
        date_time: event.date_time,
        location_name: event.location_name,
        location_type: event.location_type,
        weather_condition: "sun",
        visible_to_friends: false,
        visible_to_acquaintances: false,
        visible_to_strangers: true,
        discovery_radius_km: 100,
        source: "external",
        external_id: event.external_id,
        external_provider: event.external_provider,
        external_url: event.external_url,
        image_url: event.image_url,
        image_source: event.image_url ? "external" : null,
        status: "open",
        current_participants: 0,
        is_sponsored: false,
      };

      if (event.latitude != null && event.longitude != null) {
        payload.location_geo = `POINT(${event.longitude} ${event.latitude})`;
      }

      const { data: existing } = await supabase
        .from("activities")
        .select("id")
        .eq("source", "external")
        .eq("external_provider", event.external_provider)
        .eq("external_id", event.external_id)
        .maybeSingle();

      if (existing?.id) {
        const { error } = await supabase
          .from("activities")
          .update(payload)
          .eq("id", existing.id);
        if (error) errors.push(error.message);
        else updated++;
      } else {
        const { error } = await supabase.from("activities").insert(payload);
        if (error) errors.push(error.message);
        else inserted++;
      }
    }

    const archiveCutoff = new Date().toISOString();

    const { count: archived } = await supabase
      .from("activities")
      .select("*", { count: "exact", head: true })
      .eq("source", "external")
      .lt("date_time", archiveCutoff)
      .in("status", ["open", "full"]);

    await supabase
      .from("activities")
      .update({ status: "cancelled" })
      .eq("source", "external")
      .lt("date_time", archiveCutoff);

    const result = {
      success: true,
      started_at: startedAt,
      providers,
      mode: body?.lat != null ? "user_location" : "swiss_cities",
      query: body?.lat != null
        ? {
          latlong: formatLatLong(Number(body.lat), Number(body.lng)),
          radius_km: clampRadiusKm(Number(body.radius_km ?? DEFAULT_RADIUS_KM)),
          country_code: resolveCountryCode(
            Number(body.lat),
            Number(body.lng),
            body.country_code,
          ),
        }
        : null,
      cities: geoQueries.length,
      fetched: unique.size,
      inserted,
      updated,
      archived: archived ?? 0,
      errors: errors.slice(0, 10),
    };

    const { error: logError } = await supabase.from("external_event_sync_log").insert({
      providers,
      fetched: unique.size,
      inserted,
      updated,
      archived: archived ?? 0,
      errors: errors.length > 0 ? errors.slice(0, 20) : null,
    });
    if (logError) {
      console.warn("Sync-Log nicht geschrieben (Migration 00012?):", logError.message);
    }

    console.log("sync-external-events", JSON.stringify(result));

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("sync-external-events failed", message);

    return new Response(JSON.stringify({ error: message, started_at: startedAt }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
