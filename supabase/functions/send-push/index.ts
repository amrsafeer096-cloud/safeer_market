// Dispatches FCM v1 push notifications for order / notification events.
//
// Two callers are supported (deploy with --no-verify-jwt so both work):
//
// 1. Flutter  →  supabase.functions.invoke('send-push', body: {
//                  order_id, trigger: 'insert'|'status'|'location',
//                  previous_status? })
//    Auth: the signed-in user's JWT (Authorization: Bearer …).
//
// 2. DB webhook / pg_net  →  POST with header x-push-secret and body
//    { type, table, record, old_record } (Vault secrets push_webhook_*).
//
//   orders INSERT              → admins + takers ("طلب جديد"), order chime.
//   orders UPDATE (status)     → customer lifecycle stages (preparing /
//                                out_for_delivery / delivered / cancelled).
//   orders UPDATE (driver GPS) → one-shot "arriving soon" when ≤ 600 m.
//   app_notifications INSERT   → target user, or every customer (broadcast).
//
// Secrets: FIREBASE_SERVICE_ACCOUNT, PUSH_WEBHOOK_SECRET, optional PUBLIC_WEB_URL.
// Deploy: supabase functions deploy send-push --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";
import {
  androidPushConfig,
  apnsPushConfig,
  googleAccessToken,
  sendFcmMessage,
  serviceAccount,
} from "../_shared/fcm.ts";

type PushRole = "admin" | "taker" | "delivery" | "customer";

interface WebhookBody {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
}

interface TokenRow {
  token: string;
  role: PushRole;
  platform: string;
}

interface Push {
  title: string;
  body: string;
  type: string;
  routes: Partial<Record<PushRole | "default", string>>;
  data?: Record<string, string>;
  urgent?: boolean;
  /** Prefer the order-chime channel even when not a new_order admin alert. */
  channel?: "orders" | "alerts";
}

const APP_NAME = "سفير ماركت";
const ORDERS_CHANNEL = "safeer_orders";
const ALERTS_CHANNEL = "safeer_alerts";
const WEB_URL = (Deno.env.get("PUBLIC_WEB_URL") ??
  "https://safeer-market.web.app").replace(/\/+$/, "");
const CONCURRENCY = 25;
/** ~3 minutes at typical city delivery speed (~12–20 km/h). */
const ARRIVING_SOON_METERS = 600;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const text = (value: unknown) =>
  value === null || value === undefined ? "" : String(value).trim();

const shortId = (id: unknown) => text(id).slice(0, 8);

const money = (value: unknown) => {
  const amount = Number(value);
  return Number.isFinite(amount) ? `${amount.toFixed(2)} ج.م` : "";
};

const num = (value: unknown): number | null => {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : null;
};

/** Same normalization as OrderStatus.normalize in the app. */
function normalizeStatus(value: unknown): string {
  const compact = text(value).toLowerCase().replace(/[\s_-]/g, "");
  return ({
    pending: "pending",
    new: "pending",
    processing: "preparing",
    preparing: "preparing",
    readyfordelivery: "ready_for_delivery",
    outfordelivery: "out_for_delivery",
    delivered: "delivered",
    completed: "delivered",
    cancelled: "cancelled",
    canceled: "cancelled",
  } as Record<string, string>)[compact] ?? compact;
}

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function haversineMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * 6371000 * Math.asin(Math.sqrt(a));
}

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

async function tokensForRoles(roles: PushRole[]): Promise<TokenRow[]> {
  const { data, error } = await admin
    .from("user_fcm_tokens")
    .select("token, role, platform")
    .in("role", roles);
  if (error) throw new Error(error.message);
  return data ?? [];
}

async function tokensForUser(userId: string): Promise<TokenRow[]> {
  const { data, error } = await admin
    .from("user_fcm_tokens")
    .select("token, role, platform")
    .eq("user_id", userId);
  if (error) throw new Error(error.message);
  return data ?? [];
}

async function resolveDriverContact(record: Record<string, unknown>) {
  let name = text(record.driver_name);
  let phone = text(record.driver_phone);
  const driverId = text(record.driver_id);
  if (driverId && (!name || !phone)) {
    const { data } = await admin
      .from("profiles")
      .select("full_name, phone")
      .eq("id", driverId)
      .maybeSingle();
    name = name || text(data?.full_name);
    phone = phone || text(data?.phone);
  }
  if (!phone && name) {
    const { data } = await admin
      .from("staff")
      .select("phone")
      .eq("name", name)
      .eq("role", "driver")
      .limit(1)
      .maybeSingle();
    phone = text(data?.phone);
  }
  return { name: name || "المندوب", phone };
}

/** Claim the one-shot arriving-soon flag; returns false if already sent. */
async function claimArrivingSoon(orderId: string): Promise<boolean> {
  const { data, error } = await admin
    .from("orders")
    .update({ arriving_soon_notified: true })
    .eq("id", orderId)
    .eq("arriving_soon_notified", false)
    .select("id");
  if (error) {
    console.error(`claimArrivingSoon: ${error.message}`);
    return false;
  }
  return (data?.length ?? 0) > 0;
}

function customerLifecyclePush(
  record: Record<string, unknown>,
  status: string,
  driver: { name: string; phone: string },
): Push | null {
  const id = text(record.id);
  const preparer = text(record.preparer_name) || "المحضر";

  switch (status) {
    case "preparing":
      return {
        title: "جاري تجهيز طلبك 🛒",
        body: `تم استلام الأوردر من المحضر ${preparer} وجاري تجهيزه.`,
        type: "order",
        routes: { default: "/orders" },
        data: { order_id: id, status, stage: "preparing" },
      };
    case "out_for_delivery": {
      const phoneLine = driver.phone
        ? ` للتواصل: ${driver.phone}`
        : "";
      return {
        title: "طلبك في الطريق إليك 🛵",
        body:
          `طلبك مع مندوب التوصيل ${driver.name} وهو في طريقه إليك!${phoneLine}`,
        type: "order",
        routes: { default: `/orders/${id}/track` },
        data: {
          order_id: id,
          status,
          stage: "out_for_delivery",
          driver_name: driver.name,
          ...(driver.phone ? { driver_phone: driver.phone } : {}),
        },
        channel: "orders",
      };
    }
    case "delivered":
      return {
        title: "تم تسليم الأوردر بنجاح ✅",
        body:
          "نتمنى لك تجربة سعيدة! اضغط هنا لتقييم خدمة التوصيل وجودة المنتجات.",
        type: "order",
        routes: { default: `/orders/${id}/rate` },
        data: {
          order_id: id,
          status,
          stage: "delivered",
          action: "rate_order",
        },
      };
    case "ready_for_delivery":
      return {
        title: `تحديث طلبك #${shortId(id)}`,
        body: "طلبك جاهز وسيخرج للتوصيل قريبًا.",
        type: "order",
        routes: { default: "/orders" },
        data: { order_id: id, status, stage: "ready_for_delivery" },
      };
    case "cancelled":
      return {
        title: `تحديث طلبك #${shortId(id)}`,
        body: "تم إلغاء طلبك.",
        type: "order",
        routes: { default: "/orders" },
        data: { order_id: id, status, stage: "cancelled" },
      };
    default:
      return null;
  }
}

/** Decides who hears about a database event, and what they see. */
async function plan(
  event: WebhookBody,
): Promise<{ push: Push; tokens: TokenRow[] } | null> {
  const record = event.record ?? {};
  const old = event.old_record ?? {};

  if (event.table === "orders" && event.type === "INSERT") {
    const name = text(record.customer_name);
    const total = money(record.total_amount);
    const body = [
      `طلب جديد #${shortId(record.id)}`,
      name && `للعميل ${name}`,
      total && `الإجمالي ${total}`,
    ].filter(Boolean).join(" • ");
    return {
      push: {
        title: "طلب جديد",
        body,
        type: "new_order",
        routes: { admin: "/admin/orders", taker: "/warehouse" },
        data: { order_id: text(record.id) },
        urgent: true,
        channel: "orders",
      },
      tokens: await tokensForRoles(["admin", "taker"]),
    };
  }

  if (event.table === "orders" && event.type === "UPDATE") {
    const status = normalizeStatus(record.status);
    const oldStatus = normalizeStatus(old.status);
    const userId = text(record.user_id);
    const id = text(record.id);

    // Stage 3: driver GPS crossed the arriving-soon radius (once per order).
    const gpsChanged =
      num(record.driver_lat) !== num(old.driver_lat) ||
      num(record.driver_lng) !== num(old.driver_lng);
    if (
      gpsChanged &&
      status === "out_for_delivery" &&
      !record.arriving_soon_notified &&
      userId
    ) {
      const dLat = num(record.driver_lat);
      const dLng = num(record.driver_lng);
      const cLat = num(record.delivery_latitude);
      const cLng = num(record.delivery_longitude);
      if (
        dLat != null && dLng != null && cLat != null && cLng != null &&
        haversineMeters(dLat, dLng, cLat, cLng) <= ARRIVING_SOON_METERS
      ) {
        if (!(await claimArrivingSoon(id))) return null;
        return {
          push: {
            title: "استعد، طلبك على وشك الوصول! 📍",
            body: "مندوب التوصيل على بُعد 3 دقائق تقريباً من عنوانك.",
            type: "order",
            routes: { default: `/orders/${id}/track` },
            data: {
              order_id: id,
              status,
              stage: "arriving_soon",
            },
            channel: "orders",
          },
          tokens: await tokensForUser(userId),
        };
      }
      return null;
    }

    if (status === oldStatus || !userId) return null;
    const driver = await resolveDriverContact(record);
    const push = customerLifecyclePush(record, status, driver);
    if (!push) return null;
    return { push, tokens: await tokensForUser(userId) };
  }

  if (event.table === "app_notifications" && event.type === "INSERT") {
    const target = text(record.target_user_id);
    const type = text(record.type) || "general";
    const id = text(record.id);
    const routes: Push["routes"] = type === "support_chat"
      ? { default: "/support/chat" }
      : type === "order"
      ? { default: "/orders" }
      : { default: "/notifications" };
    return {
      push: {
        title: text(record.title) || APP_NAME,
        body: text(record.body),
        type,
        routes,
        data: {
          notification_id: id,
          ...(text(record.image_url) ? { image: text(record.image_url) } : {}),
        },
      },
      tokens: target
        ? await tokensForUser(target)
        : await tokensForRoles(["customer"]),
    };
  }

  return null;
}

function buildMessage(push: Push, row: TokenRow): Record<string, unknown> {
  const route = push.routes[row.role] ?? push.routes.default ?? "/notifications";
  const tag = push.data?.notification_id ||
    `${push.data?.order_id ?? ""}:${push.data?.stage ?? push.type}`;
  const image = push.data?.image;
  const useOrdersChannel = push.urgent || push.channel === "orders";
  const data: Record<string, string> = {
    ...push.data,
    type: push.type,
    route,
    title: push.title,
    body: push.body,
  };
  // FCM data values must be strings.
  for (const key of Object.keys(data)) {
    data[key] = String(data[key] ?? "");
  }
  return {
    token: row.token,
    notification: {
      title: push.title,
      body: push.body,
      ...(image ? { image } : {}),
    },
    data,
    android: androidPushConfig({
      channelId: useOrdersChannel ? ORDERS_CHANNEL : ALERTS_CHANNEL,
      sound: useOrdersChannel && push.urgent ? "order_chime" : "default",
      tag,
      urgent: push.urgent,
    }),
    apns: apnsPushConfig({
      sound: push.urgent ? "order_chime.caf" : "default",
      urgent: push.urgent,
    }),
    webpush: {
      headers: { Urgency: "high", TTL: push.urgent ? "1800" : "86400" },
      notification: {
        title: push.title,
        body: push.body,
        icon: `${WEB_URL}/icons/Icon-192.png`,
        badge: `${WEB_URL}/icons/Icon-192.png`,
        ...(image ? { image } : {}),
        tag,
        renotify: true,
        requireInteraction: Boolean(push.urgent),
        silent: false,
        dir: "rtl",
        lang: "ar",
      },
      fcm_options: { link: `${WEB_URL}/#${route}` },
    },
  };
}

/** Flutter invoke body: { order_id, trigger, previous_status? }. */
interface AppInvokeBody {
  order_id?: string;
  trigger?: string;
  previous_status?: string;
  // Legacy / webhook fields may also be present.
  type?: string;
  table?: string;
  record?: Record<string, unknown> | null;
  old_record?: Record<string, unknown> | null;
}

async function authorize(
  request: Request,
): Promise<{ ok: true } | { ok: false; response: Response }> {
  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  const given = request.headers.get("x-push-secret") ?? "";
  if (secret && given && safeEqual(given, secret)) {
    return { ok: true };
  }

  // Flutter supabase.functions.invoke attaches the user JWT.
  const auth = request.headers.get("Authorization") ?? "";
  if (!auth.toLowerCase().startsWith("bearer ")) {
    return {
      ok: false,
      response: json({
        error:
          "Unauthorized: pass x-push-secret (webhook) or a user JWT (app invoke)",
      }, 401),
    };
  }
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) {
    return {
      ok: false,
      response: json({ error: "Unauthorized: invalid session" }, 401),
    };
  }
  return { ok: true };
}

/** Turns a Flutter { order_id, trigger } call into a webhook-shaped event. */
async function eventFromAppInvoke(
  body: AppInvokeBody,
): Promise<WebhookBody | null> {
  const orderId = text(body.order_id);
  const trigger = text(body.trigger).toLowerCase();
  if (!orderId || !trigger) return null;

  const { data: record, error } = await admin
    .from("orders")
    .select("*")
    .eq("id", orderId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!record) return null;

  if (trigger === "insert" || trigger === "created" || trigger === "new") {
    return {
      type: "INSERT",
      table: "orders",
      record,
      old_record: null,
    };
  }

  if (trigger === "status" || trigger === "status_changed") {
    const previous = text(body.previous_status) || "pending";
    return {
      type: "UPDATE",
      table: "orders",
      record,
      old_record: { ...record, status: previous },
    };
  }

  if (
    trigger === "location" ||
    trigger === "driver_location" ||
    trigger === "arriving_soon"
  ) {
    // Pretend GPS just changed from "far away" so plan() evaluates distance.
    return {
      type: "UPDATE",
      table: "orders",
      record,
      old_record: {
        ...record,
        driver_lat: null,
        driver_lng: null,
      },
    };
  }

  return null;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);

  const auth = await authorize(request);
  if (!auth.ok) return auth.response;

  const body = await request.json().catch(() => null) as AppInvokeBody | null;
  if (!body) return json({ error: "Expected JSON body" }, 400);

  let event: WebhookBody | null = null;
  if (body.table && body.type) {
    event = {
      type: body.type as WebhookBody["type"],
      table: body.table,
      record: body.record ?? null,
      old_record: body.old_record ?? null,
    };
  } else {
    event = await eventFromAppInvoke(body);
  }
  if (!event?.table || !event.type) {
    return json({
      error:
        "Expected { type, table, record } or { order_id, trigger: insert|status|location }",
    }, 400);
  }

  console.log(
    `send-push: ${event.type} ${event.table} ` +
      `id=${text(event.record?.id)} status=${text(event.record?.status)}`,
  );

  const planned = await plan(event);
  if (!planned || planned.tokens.length === 0) {
    console.log("send-push: skipped (no plan or no tokens)");
    return json({ sent: 0, skipped: true });
  }

  const account = serviceAccount();
  const accessToken = await googleAccessToken(account);
  const stale: string[] = [];
  let sent = 0;
  let failed = 0;

  const queue = [...planned.tokens];
  await Promise.all(
    Array.from({ length: Math.min(CONCURRENCY, queue.length) }, async () => {
      for (let row = queue.shift(); row; row = queue.shift()) {
        const result = await sendFcmMessage(
          account,
          accessToken,
          buildMessage(planned.push, row),
        );
        if (result.ok) {
          sent++;
        } else {
          failed++;
          if (result.unregistered) stale.push(row.token);
          else console.error(`FCM ${result.status}: ${result.error}`);
        }
      }
    }),
  );

  if (stale.length > 0) {
    await admin.from("user_fcm_tokens").delete().in("token", stale);
  }
  console.log(`send-push: sent=${sent} failed=${failed} pruned=${stale.length}`);
  return json({ sent, failed, pruned: stale.length });
});
