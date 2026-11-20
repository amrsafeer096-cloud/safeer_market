// Sends "طلب جديد متاح للتوصيل!" to every device subscribed to the FCM
// "drivers" topic. Called by the warehouse app when an order is marked
// ready_for_delivery.
//
// Secrets (Dashboard > Edge Functions > Secrets):
//   FIREBASE_SERVICE_ACCOUNT  the Firebase service-account JSON, pasted whole.
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided
// by Supabase automatically.

import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const DRIVERS_TOPIC = "drivers";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const key = await importPKCS8(account.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error(`Google OAuth failed: ${await response.text()}`);
  }
  return (await response.json()).access_token;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);

  const { order_id: orderId } = await request.json().catch(() => ({}));
  if (typeof orderId !== "string" || orderId.length === 0) {
    return json({ error: "order_id is required" }, 400);
  }

  // Only warehouse staff (or an admin) may announce an order, and only once
  // it is ready_for_delivery, so the endpoint can't be used to spam drivers.
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: request.headers.get("Authorization") ?? "" } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "Not signed in" }, 401);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: caller } = await admin
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle();
  if (caller?.role !== "warehouse" && caller?.role !== "admin") {
    return json({ error: "Not allowed" }, 403);
  }

  const { data: order } = await admin
    .from("orders")
    .select("id, status, driver_id")
    .eq("id", orderId)
    .maybeSingle();
  if (
    !order || order.status !== "ready_for_delivery" || order.driver_id !== null
  ) {
    return json({ error: "Order not found" }, 404);
  }

  const account: ServiceAccount = JSON.parse(
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!,
  );
  const accessToken = await googleAccessToken(account);

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          topic: DRIVERS_TOPIC,
          notification: {
            title: "سفير ماركت",
            body: "طلب جديد متاح للتوصيل!",
          },
          data: { type: "new_order", order_id: String(order.id) },
          android: { priority: "high" },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    },
  );
  if (!response.ok) {
    return json({ error: `FCM failed: ${await response.text()}` }, 502);
  }
  return json({ sent: true });
});
