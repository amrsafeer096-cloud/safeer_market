// Dispatches FCM v1 push notifications for database events. Called by the
// dispatch_push_webhook() trigger (migration 20261120100000) with the body
// of a Supabase Database Webhook: { type, table, record, old_record }.
//
//   orders INSERT            → admins and order takers ("طلب جديد"), with the
//                              order chime, even when the app is closed.
//   orders UPDATE (status)   → the order's customer.
//   app_notifications INSERT → its target_user_id, or every customer device
//                              for a broadcast (target_user_id null).
//
// Secrets (Dashboard > Edge Functions > Secrets):
//   FIREBASE_SERVICE_ACCOUNT  the Firebase service-account JSON, pasted whole.
//   PUSH_WEBHOOK_SECRET       same value as the vault secret
//                             'push_webhook_secret'.
//   PUBLIC_WEB_URL            optional, the hosted web app used for links in
//                             desktop notifications (default below).
// Deploy without JWT verification; the shared secret authenticates calls:
//   supabase functions deploy send-push --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";
import {
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
  /** `type` in the data payload; the app picks the channel and route by it. */
  type: string;
  /** In-app route per recipient role (falls back to `default`). */
  routes: Partial<Record<PushRole | "default", string>>;
  data?: Record<string, string>;
  /** New orders ring the custom chime and stay on screen. */
  urgent?: boolean;
}

const APP_NAME = "سفير ماركت";
const ORDERS_CHANNEL = "safeer_orders";
const ALERTS_CHANNEL = "safeer_alerts";
const WEB_URL = (Deno.env.get("PUBLIC_WEB_URL") ??
  "https://safeer-market.web.app").replace(/\/+$/, "");
const CONCURRENCY = 25;

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
    cancelled: "cancelled",
    canceled: "cancelled",
  } as Record<string, string>)[compact] ?? compact;
}

const CUSTOMER_STATUS_MESSAGES: Record<string, string> = {
  preparing: "جاري تجهيز طلبك الآن.",
  ready_for_delivery: "طلبك جاهز وسيخرج للتوصيل قريبًا.",
  out_for_delivery: "طلبك في الطريق إليك!",
  delivered: "تم توصيل طلبك. بالهنا والشفا!",
  cancelled: "تم إلغاء طلبك.",
};

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
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

/** Decides who hears about a database event, and what they see. */
async function plan(
  event: WebhookBody,
): Promise<{ push: Push; tokens: TokenRow[] } | null> {
  const record = event.record ?? {};

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
      },
      tokens: await tokensForRoles(["admin", "taker"]),
    };
  }

  if (event.table === "orders" && event.type === "UPDATE") {
    const status = normalizeStatus(record.status);
    if (status === normalizeStatus(event.old_record?.status)) return null;
    const message = CUSTOMER_STATUS_MESSAGES[status];
    const userId = text(record.user_id);
    if (!message || !userId) return null;
    const id = text(record.id);
    return {
      push: {
        title: `تحديث طلبك #${shortId(id)}`,
        body: message,
        type: "order",
        routes: { default: "/orders" },
        data: { order_id: id, status },
      },
      tokens: await tokensForUser(userId),
    };
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
  const tag = push.data?.notification_id || push.data?.order_id || push.type;
  const image = push.data?.image;
  const data: Record<string, string> = {
    ...push.data,
    type: push.type,
    route,
    title: push.title,
    body: push.body,
  };
  return {
    token: row.token,
    notification: {
      title: push.title,
      body: push.body,
      ...(image ? { image } : {}),
    },
    data,
    android: {
      priority: "high",
      ttl: push.urgent ? "1800s" : "86400s",
      notification: {
        channel_id: push.urgent ? ORDERS_CHANNEL : ALERTS_CHANNEL,
        sound: push.urgent ? "order_chime" : "default",
        tag,
        notification_priority: push.urgent ? "PRIORITY_MAX" : "PRIORITY_HIGH",
        default_vibrate_timings: true,
      },
    },
    apns: {
      headers: { "apns-priority": "10", "apns-push-type": "alert" },
      payload: {
        aps: {
          // Falls back to the default sound if order_chime.caf isn't bundled.
          sound: push.urgent ? "order_chime.caf" : "default",
        },
      },
    },
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

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);

  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  const given = request.headers.get("x-push-secret") ?? "";
  if (!secret || !safeEqual(given, secret)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const event = await request.json().catch(() => null) as WebhookBody | null;
  if (!event?.table || !event.type) {
    return json({ error: "Expected a database webhook body" }, 400);
  }

  const planned = await plan(event);
  if (!planned || planned.tokens.length === 0) {
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
  return json({ sent, failed, pruned: stale.length });
});
