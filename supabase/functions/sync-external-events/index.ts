import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EVENTFROG_BASE = "https://api.eventfrog.net/api/v1";
const EVENTFROG_PROVIDER = "eventfrog";
const LEGACY_PROVIDERS = ["ticketmaster", "eventbrite", "circleveya_curated"];
const DEFAULT_RADIUS_KM = 25;
const MAX_RADIUS_KM = 200;
const PER_PAGE = 100;
const MAX_PAGES = 3;
const MAX_EVENTS_TO_SYNC = 150;
const FETCH_TIMEOUT_MS = 12_000;

type GeoQuery = {
  lat: number;
  lng: number;
  radiusKm: number;
};

type SyncRequestBody = {
  lat?: number;
  lng?: number;
  radius_km?: number;
  country_code?: string;
  expand_radius?: boolean;
};

type EventfrogImage = {
  url?: string;
  width?: number;
  height?: number;
};

type EventfrogEventRaw = {
  id: string;
  title?: string[] | Record<string, string>;
  url?: string;
  presaleLink?: string;
  begin?: string;
  end?: string;
  cancelled?: boolean;
  visible?: boolean;
  published?: boolean;
  emblemToShow?: EventfrogImage | null;
  shortDescription?: string[] | Record<string, string>;
  descriptionAsHTML?: string[] | Record<string, string>;
  locationIds?: string[];
};

type EventfrogLocationRaw = {
  id: string;
  title?: string[] | Record<string, string>;
  addressLine?: string;
  zip?: string;
  city?: string;
  lat?: number;
  lng?: number;
};

type NormalizedEvent = {
  external_id: string;
  external_provider: string;
  title: string;
  description: string | null;
  start_date: string | null;
  end_date: string | null;
  city: string | null;
  location_name: string | null;
  latitude: number | null;
  longitude: number | null;
  image_url: string | null;
  external_url: string;
  raw_data: Record<string, unknown> | null;
};

type EventfrogFetchResult = {
  events: NormalizedEvent[];
  attempts: string[];
  warnings: string[];
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SWISS_DEFAULTS = {
  frauenfeld: { lat: 47.5569, lng: 8.8982 },
};

const RADIUS_STEPS = [5, 10, 25, 50, 100, 200];

function getEventfrogApiKey(): string | null {
  const raw = Deno.env.get("EVENTFROG_API_KEY");
  if (!raw) return null;
  const cleaned = raw.trim().replace(/^['"]+|['"]+$/g, "");
  return cleaned.length > 0 ? cleaned : null;
}

function clampRadiusKm(radiusKm: number): number {
  if (!Number.isFinite(radiusKm) || radiusKm <= 0) return DEFAULT_RADIUS_KM;
  return Math.min(MAX_RADIUS_KM, Math.max(1, Math.round(radiusKm)));
}

function formatEventfrogDate(date: Date): string {
  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const year = date.getFullYear();
  return `${day}.${month}.${year}`;
}

function localizedText(
  value: string[] | Record<string, string> | undefined,
  preferred = "de",
): string | null {
  if (!value) return null;
  if (Array.isArray(value)) {
    if (value.length === 0) return null;
    return value[0] ?? null;
  }
  if (typeof value === "object") {
    if (preferred in value && value[preferred]) return value[preferred];
    const first = Object.values(value).find((v) => typeof v === "string" && v);
    return first ?? null;
  }
  return null;
}

function stripHtml(html: string): string {
  return html
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/\s+/g, " ")
    .trim();
}

function appendSearchParams(
  params: URLSearchParams,
  key: string,
  value: string | number | string[] | undefined,
) {
  if (value === undefined || value === null) return;
  if (Array.isArray(value)) {
    for (const item of value) {
      if (item) params.append(key, item);
    }
    return;
  }
  params.append(key, String(value));
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

function resolveUserGeo(body: SyncRequestBody | null): GeoQuery {
  const lat = body?.lat != null && Number.isFinite(body.lat)
    ? Number(body.lat)
    : SWISS_DEFAULTS.frauenfeld.lat;
  const lng = body?.lng != null && Number.isFinite(body.lng)
    ? Number(body.lng)
    : SWISS_DEFAULTS.frauenfeld.lng;

  return {
    lat: Number(lat.toFixed(4)),
    lng: Number(lng.toFixed(4)),
    radiusKm: clampRadiusKm(Number(body?.radius_km ?? DEFAULT_RADIUS_KM)),
  };
}

function normalizeTitle(title: string): string | null {
  const trimmed = title.trim();
  if (trimmed.length < 3) return null;
  if (trimmed.length > 120) return trimmed.slice(0, 120);
  return trimmed;
}

function normalizeDateTime(value: string | undefined): string | null {
  if (!value || typeof value !== "string") return null;
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) return null;
  return new Date(parsed).toISOString();
}

function dedupeEvents(events: NormalizedEvent[]): NormalizedEvent[] {
  const seen = new Set<string>();
  const result: NormalizedEvent[] = [];
  for (const event of events) {
    const key = `${event.external_provider}:${event.external_id}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(event);
  }
  return result;
}

async function eventfrogGet<T>(
  apiKey: string,
  endpoint: string,
  query: Record<string, string | number | string[] | undefined>,
): Promise<{ ok: boolean; status: number; data: T | null; bodyText: string }> {
  const params = new URLSearchParams();
  params.append("apiKey", apiKey);
  for (const [key, value] of Object.entries(query)) {
    appendSearchParams(params, key, value);
  }

  const url = `${EVENTFROG_BASE}${endpoint}?${params}`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      headers: { Accept: "application/json" },
      signal: controller.signal,
    });
    const bodyText = await response.text();

    if (!response.ok) {
      return { ok: false, status: response.status, data: null, bodyText };
    }

    try {
      return {
        ok: true,
        status: response.status,
        data: JSON.parse(bodyText) as T,
        bodyText,
      };
    } catch {
      return { ok: false, status: response.status, data: null, bodyText };
    }
  } catch {
    return { ok: false, status: 0, data: null, bodyText: "fetch aborted" };
  } finally {
    clearTimeout(timeout);
  }
}

async function fetchEventfrogLocations(
  apiKey: string,
  locationIds: string[],
): Promise<Map<string, EventfrogLocationRaw>> {
  const map = new Map<string, EventfrogLocationRaw>();
  const chunkSize = 40;

  for (let i = 0; i < locationIds.length; i += chunkSize) {
    const chunk = locationIds.slice(i, i + chunkSize);
    try {
      const result = await eventfrogGet<{
        locations?: EventfrogLocationRaw[];
      }>(apiKey, "/locations.json", { id: chunk });

      if (!result.ok || !result.data?.locations) continue;
      for (const location of result.data.locations) {
        if (location?.id) map.set(location.id, location);
      }
    } catch {
      // Einzelner Location-Request darf fehlschlagen
    }
  }

  return map;
}

function resolveTicketUrl(event: EventfrogEventRaw): string | null {
  if (typeof event.presaleLink === "string" && event.presaleLink.length > 0) {
    return event.presaleLink;
  }
  if (typeof event.url === "string" && event.url.length > 0) {
    return event.url;
  }
  return null;
}

function buildLocationName(location: EventfrogLocationRaw | undefined): string | null {
  if (!location) return null;
  const title = localizedText(location.title);
  const parts = [title, location.addressLine, location.zip, location.city]
    .filter((part) => typeof part === "string" && part.trim().length > 0);
  return parts.length > 0 ? parts.join(", ") : null;
}

function mapEventfrogEvent(
  event: EventfrogEventRaw,
  locations: Map<string, EventfrogLocationRaw>,
): NormalizedEvent | null {
  if (!event.id) return null;
  if (event.cancelled === true) return null;
  if (event.visible === false || event.published === false) return null;

  const titleRaw = localizedText(event.title);
  const title = titleRaw ? normalizeTitle(titleRaw) : null;
  const ticketUrl = resolveTicketUrl(event);
  if (!title || !ticketUrl) return null;

  const shortDesc = localizedText(event.shortDescription);
  const htmlDesc = localizedText(event.descriptionAsHTML);
  const description = shortDesc ??
    (htmlDesc ? stripHtml(htmlDesc) : null);

  const locationId = event.locationIds?.[0];
  const location = locationId ? locations.get(locationId) : undefined;
  const locationName = buildLocationName(location);
  const city = typeof location?.city === "string" && location.city.trim()
    ? location.city.trim()
    : null;

  const latitude = typeof location?.lat === "number" ? location.lat : null;
  const longitude = typeof location?.lng === "number" ? location.lng : null;

  const imageUrl = typeof event.emblemToShow?.url === "string"
    ? event.emblemToShow.url
    : null;

  return {
    external_id: event.id,
    external_provider: EVENTFROG_PROVIDER,
    title,
    description: description ? description.slice(0, 2000) : null,
    start_date: normalizeDateTime(event.begin),
    end_date: normalizeDateTime(event.end),
    city,
    location_name: locationName,
    latitude: Number.isFinite(latitude) ? latitude : null,
    longitude: Number.isFinite(longitude) ? longitude : null,
    image_url: imageUrl,
    external_url: ticketUrl,
    raw_data: {
      id: event.id,
      begin: event.begin ?? null,
      end: event.end ?? null,
      locationId: locationId ?? null,
    },
  };
}

async function fetchEventfrogPage(
  apiKey: string,
  geo: GeoQuery,
  radiusKm: number,
  page: number,
): Promise<{
  events: EventfrogEventRaw[];
  total: number;
  status: number;
  bodyText: string;
}> {
  const result = await eventfrogGet<{
    totalNumberOfResources?: number;
    events?: EventfrogEventRaw[];
  }>(apiKey, "/events.json", {
    lat: geo.lat,
    lng: geo.lng,
    r: radiusKm,
    perPage: PER_PAGE,
    page,
    from: formatEventfrogDate(new Date()),
  });

  if (!result.ok || !result.data) {
    return {
      events: [],
      total: 0,
      status: result.status,
      bodyText: result.bodyText,
    };
  }

  return {
    events: result.data.events ?? [],
    total: result.data.totalNumberOfResources ?? 0,
    status: result.status,
    bodyText: result.bodyText,
  };
}

async function fetchAllEventfrogEventsForRadius(
  apiKey: string,
  geo: GeoQuery,
  radiusKm: number,
  label: string,
  attempts: string[],
  warnings: string[],
): Promise<EventfrogEventRaw[]> {
  const collected: EventfrogEventRaw[] = [];
  let total = 0;

  for (let page = 1; page <= MAX_PAGES; page++) {
    try {
      const result = await fetchEventfrogPage(apiKey, geo, radiusKm, page);
      if (page === 1 && result.status !== 200) {
        attempts.push(`${label} r=${radiusKm}km → HTTP ${result.status}`);
        warnings.push(`${label}: HTTP ${result.status}`);
        break;
      }

      if (page === 1) {
        total = result.total;
        attempts.push(`${label} r=${radiusKm}km → total ${total}`);
      }

      if (result.events.length === 0) break;
      collected.push(...result.events);

      if (collected.length >= total || result.events.length < PER_PAGE) break;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      warnings.push(`${label} page ${page}: ${message}`);
      break;
    }
  }

  return collected;
}

async function fetchEventfrogForRegion(
  apiKey: string,
  userGeo: GeoQuery,
  expandRadius: boolean,
): Promise<EventfrogFetchResult> {
  const attempts: string[] = [];
  const warnings: string[] = [];
  const radii = expandRadius
    ? Array.from(
      new Set([
        userGeo.radiusKm,
        ...RADIUS_STEPS.filter((r) => r > userGeo.radiusKm),
      ]),
    ).sort((a, b) => a - b)
    : [userGeo.radiusKm];

  let rawEvents: EventfrogEventRaw[] = [];

  for (const radiusKm of radii) {
    const batch = await fetchAllEventfrogEventsForRadius(
      apiKey,
      userGeo,
      radiusKm,
      "eventfrog geo",
      attempts,
      warnings,
    );
    rawEvents.push(...batch);
    rawEvents = dedupeRawEvents(rawEvents);
    if (rawEvents.length > 0) break;
  }

  const locationIds = Array.from(
    new Set(
      rawEvents
        .map((event) => event.locationIds?.[0])
        .filter((id): id is string => typeof id === "string" && id.length > 0),
    ),
  );

  const locations = await fetchEventfrogLocations(apiKey, locationIds);

  const events = rawEvents
    .map((event) => mapEventfrogEvent(event, locations))
    .filter((event): event is NormalizedEvent => event != null)
    .slice(0, MAX_EVENTS_TO_SYNC);

  return {
    events: dedupeEvents(events),
    attempts,
    warnings,
  };
}

function dedupeRawEvents(events: EventfrogEventRaw[]): EventfrogEventRaw[] {
  const seen = new Set<string>();
  const result: EventfrogEventRaw[] = [];
  for (const event of events) {
    if (!event.id || seen.has(event.id)) continue;
    seen.add(event.id);
    result.push(event);
  }
  return result;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startedAt = new Date().toISOString();
  const errors: string[] = [];

  try {
    const body = await readSyncRequestBody(req);
    const userGeo = resolveUserGeo(body);
    const expandRadius = body?.expand_radius !== false;
    const apiKey = getEventfrogApiKey();

    const eventfrog = apiKey
      ? await fetchEventfrogForRegion(apiKey, userGeo, expandRadius)
      : {
        events: [],
        attempts: ["no_api_key"],
        warnings: ["EVENTFROG_API_KEY nicht gesetzt"],
      };

    const uniqueEvents = eventfrog.events;
    const strategy = !apiKey
      ? "eventfrog_no_api_key"
      : uniqueEvents.length > 0
      ? "eventfrog_geo"
      : "eventfrog_empty";

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    let upserted = 0;
    const chunkSize = 50;

    for (let i = 0; i < uniqueEvents.length; i += chunkSize) {
      const chunk = uniqueEvents.slice(i, i + chunkSize);
      const rows = chunk.map((event) => {
        const lat = event.latitude ?? userGeo.lat;
        const lng = event.longitude ?? userGeo.lng;
        return {
          provider: event.external_provider,
          external_id: event.external_id,
          title: event.title,
          description: event.description,
          start_date: event.start_date,
          end_date: event.end_date,
          city: event.city,
          location_name: event.location_name,
          latitude: Number.isFinite(lat) ? lat : null,
          longitude: Number.isFinite(lng) ? lng : null,
          location_geo: Number.isFinite(lat) && Number.isFinite(lng)
            ? `POINT(${lng} ${lat})`
            : null,
          image_url: event.image_url,
          external_url: event.external_url,
          raw_data: event.raw_data,
          is_cancelled: false,
          synced_at: new Date().toISOString(),
        };
      });

      try {
        const { error, count } = await supabase
          .from("external_events")
          .upsert(rows, {
            onConflict: "provider,external_id",
            count: "exact",
          });
        if (error) errors.push(error.message);
        else upserted += count ?? rows.length;
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        errors.push(`Upsert chunk ${i}: ${message}`);
      }
    }

    let archived = 0;
    try {
      const cutoff = new Date().toISOString();
      const { count } = await supabase
        .from("external_events")
        .update({ is_cancelled: true }, { count: "exact" })
        .in("provider", LEGACY_PROVIDERS)
        .eq("is_cancelled", false)
        .lt("start_date", cutoff);
      archived = count ?? 0;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      errors.push(`Archivierung: ${message}`);
    }

    const providers = apiKey ? [EVENTFROG_PROVIDER] : [];

    const result = {
      success: true,
      started_at: startedAt,
      mode: "eventfrog_cache",
      target_table: "external_events",
      providers,
      strategy,
      eventfrog_api: "api.eventfrog.net/api/v1",
      eventfrog_key_configured: !!apiKey,
      eventfrog_attempts: eventfrog.attempts,
      eventfrog_warnings: eventfrog.warnings,
      query: {
        lat: userGeo.lat,
        lng: userGeo.lng,
        radius_km: userGeo.radiusKm,
        country_code: "CH",
        expand_radius: expandRadius,
        per_page: PER_PAGE,
      },
      fetched: uniqueEvents.length,
      inserted: upserted,
      updated: 0,
      archived,
      errors: errors.slice(0, 10),
    };

    try {
      const { error: logError } = await supabase.from("external_event_sync_log").insert({
        providers,
        fetched: uniqueEvents.length,
        inserted: upserted,
        updated: 0,
        archived,
        mode: "eventfrog_cache",
        query_lat: userGeo.lat,
        query_lng: userGeo.lng,
        query_radius_km: userGeo.radiusKm,
        errors: errors.length > 0 ? errors.slice(0, 20) : null,
      });
      if (logError) {
        console.warn("Sync-Log nicht geschrieben:", logError.message);
      }
    } catch (err) {
      console.warn("Sync-Log Fehler:", err);
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
