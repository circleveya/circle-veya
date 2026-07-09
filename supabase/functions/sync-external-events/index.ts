import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EVENTBRITE_API_KEY = Deno.env.get("EVENTBRITE_API_KEY");
const TICKETMASTER_API_KEY = Deno.env.get("TICKETMASTER_API_KEY");

const DEFAULT_RADIUS_KM = 25;
const MAX_RADIUS_KM = 200;
const MIN_RESULTS_TARGET = 5;
const SWISS_TIMEZONE = "Europe/Zurich";

/** Schweizer Städte – Cron-Fallback & Hub-Suche */
const SWISS_HUBS = [
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
  expand_radius?: boolean;
  min_results?: number;
};

type FetchStrategy =
  | "user_radius"
  | "radius_expansion"
  | "national_ch"
  | "swiss_hubs"
  | "swiss_cities_cron";

type FetchMeta = {
  strategy: FetchStrategy;
  usedRadiusKm?: number;
  attempts: string[];
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function formatLatLong(lat: number, lng: number): string {
  const safeLat = Number(lat.toFixed(4));
  const safeLng = Number(lng.toFixed(4));
  return `${safeLat},${safeLng}`;
}

function clampRadiusKm(radiusKm: number, max = MAX_RADIUS_KM): number {
  if (!Number.isFinite(radiusKm) || radiusKm <= 0) return DEFAULT_RADIUS_KM;
  return Math.min(max, Math.max(1, Math.round(radiusKm)));
}

function isInSwitzerland(lat: number, lng: number): boolean {
  return lat >= 45.7 && lat <= 47.9 && lng >= 5.8 && lng <= 10.6;
}

function resolveCountryCode(lat: number, lng: number, explicit?: string): string {
  if (explicit && explicit.trim().length === 2) {
    return explicit.trim().toUpperCase();
  }
  return isInSwitzerland(lat, lng) ? "CH" : "CH";
}

/** Ticketmaster erwartet UTC ISO-8601, z. B. 2026-07-09T18:00:00Z */
function formatTicketmasterUtcDateTime(date: Date): string {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

/** Start = jetzt (Europe/Zurich → UTC), Ende = +6 Monate */
function getSwissTicketmasterDateRange(): {
  startDateTime: string;
  endDateTime: string;
} {
  const now = new Date();
  const end = new Date(now);
  end.setMonth(end.getMonth() + 6);

  return {
    startDateTime: formatTicketmasterUtcDateTime(now),
    endDateTime: formatTicketmasterUtcDateTime(end),
  };
}

function buildRadiusExpansionSteps(initialRadiusKm: number): number[] {
  const steps = [
    clampRadiusKm(initialRadiusKm),
    10,
    25,
    50,
    100,
    MAX_RADIUS_KM,
  ];
  return [...new Set(steps)].sort((a, b) => a - b);
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

function dedupeEvents(events: NormalizedEvent[]): NormalizedEvent[] {
  const unique = new Map<string, NormalizedEvent>();
  for (const event of events) {
    unique.set(`${event.external_provider}:${event.external_id}`, event);
  }
  return [...unique.values()];
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

function buildUserGeoQuery(body: SyncRequestBody): GeoQuery {
  const lat = Number(body.lat);
  const lng = Number(body.lng);
  return {
    label: `GPS ${formatLatLong(lat, lng)}`,
    lat,
    lng,
    radiusKm: clampRadiusKm(Number(body.radius_km ?? DEFAULT_RADIUS_KM)),
    countryCode: resolveCountryCode(lat, lng, body.country_code),
  };
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

type TicketmasterSearchOptions = {
  location?: GeoQuery;
  countryOnly?: boolean;
  sort?: string;
  size?: number;
};

async function fetchTicketmasterEventsRaw(
  options: TicketmasterSearchOptions,
): Promise<NormalizedEvent[]> {
  if (!TICKETMASTER_API_KEY) return [];

  const { startDateTime, endDateTime } = getSwissTicketmasterDateRange();
  const countryCode = options.location
    ? resolveCountryCode(
      options.location.lat,
      options.location.lng,
      options.location.countryCode,
    )
    : "CH";

  const params = new URLSearchParams({
    apikey: TICKETMASTER_API_KEY,
    countryCode,
    unit: "km",
    size: String(options.size ?? 20),
    sort: options.sort ?? "date,asc",
    startDateTime,
    endDateTime,
    locale: "de-ch",
    includeTBA: "no",
    includeTBD: "no",
  });

  if (options.location && !options.countryOnly) {
    const radiusKm = clampRadiusKm(options.location.radiusKm);
    params.set("latlong", formatLatLong(options.location.lat, options.location.lng));
    params.set("radius", String(radiusKm));
  }

  const url =
    `https://app.ticketmaster.com/discovery/v2/events.json?${params.toString()}`;

  const logLabel = options.countryOnly
    ? "CH-national"
    : options.location?.label ?? "CH";

  console.log(
    "Ticketmaster request",
    logLabel,
    options.countryOnly
      ? `countryCode=${countryCode} sort=${params.get("sort")}`
      : `latlong=${params.get("latlong")} radius=${params.get("radius")} unit=km countryCode=${countryCode}`,
    `startDateTime=${startDateTime}`,
    `timezone=${SWISS_TIMEZONE}`,
  );

  const res = await fetch(url);
  if (!res.ok) {
    console.error(
      "Ticketmaster error",
      logLabel,
      res.status,
      await res.text(),
    );
    return [];
  }

  const data = await res.json();
  const total = data.page?.totalElements ?? 0;
  console.log("Ticketmaster response", logLabel, `events=${total}`);

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

      const dateTime = start?.dateTime ??
        (start?.localDate && start?.localTime
          ? `${start.localDate}T${start.localTime}`
          : start?.localDate ?? null);

      return {
        external_id: String(event.id),
        external_provider: "ticketmaster",
        title,
        description: null,
        date_time: dateTime,
        location_name: (venue?.name as string) ??
          (options.location?.label ?? "Schweiz"),
        latitude: loc?.latitude
          ? parseFloat(loc.latitude)
          : options.location?.lat ?? null,
        longitude: loc?.longitude
          ? parseFloat(loc.longitude)
          : options.location?.lng ?? null,
        image_url: (image?.url as string) ?? null,
        external_url: String(event.url ?? ""),
        location_type: inferLocationType(title),
      };
    })
    .filter((e: NormalizedEvent) =>
      e.external_url.length > 0 && isFutureOrUnset(e.date_time)
    );
}

async function fetchTicketmasterWithFallback(
  baseLocation: GeoQuery,
  expandRadius: boolean,
  minResults: number,
): Promise<{ events: NormalizedEvent[]; meta: FetchMeta }> {
  const meta: FetchMeta = { strategy: "user_radius", attempts: [] };
  let collected: NormalizedEvent[] = [];

  const radii = expandRadius
    ? buildRadiusExpansionSteps(baseLocation.radiusKm)
    : [clampRadiusKm(baseLocation.radiusKm)];

  for (const radiusKm of radii) {
    const location = { ...baseLocation, radiusKm };
    const events = await fetchTicketmasterEventsRaw({ location });
    meta.attempts.push(`geo radius=${radiusKm}km → ${events.length}`);

    collected = dedupeEvents([...collected, ...events]);
    if (collected.length >= minResults) {
      meta.strategy = radiusKm === baseLocation.radiusKm
        ? "user_radius"
        : "radius_expansion";
      meta.usedRadiusKm = radiusKm;
      return { events: collected, meta };
    }
  }

  const national = await fetchTicketmasterEventsRaw({
    countryOnly: true,
    sort: "relevance,desc",
    size: 50,
  });
  meta.attempts.push(`national CH → ${national.length}`);
  collected = dedupeEvents([...collected, ...national]);

  if (collected.length >= minResults) {
    meta.strategy = "national_ch";
    return { events: collected, meta };
  }

  const hubResults = await Promise.all(
    SWISS_HUBS.slice(0, 4).map((hub) =>
      fetchTicketmasterEventsRaw({
        location: {
          ...hub,
          radiusKm: 75,
          countryCode: "CH",
        },
        sort: "relevance,desc",
        size: 15,
      })
    ),
  );

  for (const [index, events] of hubResults.entries()) {
    meta.attempts.push(`${SWISS_HUBS[index].label} hub → ${events.length}`);
    collected = dedupeEvents([...collected, ...events]);
  }

  meta.strategy = "swiss_hubs";
  return { events: collected, meta };
}

async function fetchAllExternalEvents(
  body: SyncRequestBody | null,
): Promise<{ events: NormalizedEvent[]; meta: FetchMeta; mode: string }> {
  const expandRadius = body?.expand_radius !== false;
  const minResults = Math.max(
    1,
    Math.min(50, Number(body?.min_results ?? MIN_RESULTS_TARGET)),
  );

  if (
    body?.lat != null &&
    body?.lng != null &&
    Number.isFinite(body.lat) &&
    Number.isFinite(body.lng)
  ) {
    const userLocation = buildUserGeoQuery(body);
    const [ticketmaster, eventbrite] = await Promise.all([
      fetchTicketmasterWithFallback(userLocation, expandRadius, minResults),
      fetchEventbriteEvents(userLocation),
    ]);

    return {
      events: dedupeEvents([...ticketmaster.events, ...eventbrite]),
      meta: ticketmaster.meta,
      mode: "user_location",
    };
  }

  const meta: FetchMeta = {
    strategy: "swiss_cities_cron",
    attempts: [],
  };
  let collected: NormalizedEvent[] = [];

  for (const hub of SWISS_HUBS) {
    const location: GeoQuery = {
      ...hub,
      radiusKm: 50,
      countryCode: "CH",
    };
    const [tm, eb] = await Promise.all([
      fetchTicketmasterEventsRaw({ location, size: 20 }),
      fetchEventbriteEvents(location),
    ]);
    meta.attempts.push(`${hub.label} → tm:${tm.length} eb:${eb.length}`);
    collected = dedupeEvents([...collected, ...tm, ...eb]);
  }

  if (collected.length < minResults) {
    const national = await fetchTicketmasterEventsRaw({
      countryOnly: true,
      sort: "relevance,desc",
      size: 50,
    });
    meta.attempts.push(`national CH fallback → ${national.length}`);
    collected = dedupeEvents([...collected, ...national]);
  }

  return {
    events: collected,
    meta,
    mode: "swiss_cities_cron",
  };
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

    const { events: allEvents, meta, mode } = await fetchAllExternalEvents(body);
    const unique = dedupeEvents(allEvents);

    let inserted = 0;
    let updated = 0;
    const errors: string[] = [];

    for (const event of unique) {
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

    const dateRange = getSwissTicketmasterDateRange();
    const result = {
      success: true,
      started_at: startedAt,
      providers,
      mode,
      strategy: meta.strategy,
      attempts: meta.attempts,
      used_radius_km: meta.usedRadiusKm ?? null,
      query: body?.lat != null
        ? {
          latlong: formatLatLong(Number(body.lat), Number(body.lng)),
          radius_km: clampRadiusKm(Number(body.radius_km ?? DEFAULT_RADIUS_KM)),
          country_code: resolveCountryCode(
            Number(body.lat),
            Number(body.lng),
            body.country_code,
          ),
          expand_radius: body?.expand_radius !== false,
          startDateTime: dateRange.startDateTime,
          endDateTime: dateRange.endDateTime,
        }
        : null,
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
