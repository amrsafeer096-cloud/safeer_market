// Starts a Paymob payment for a paid plan OR a grocery order and returns the
// checkout URL the app opens.
//
// Subscription:
//   POST { tier: "vip" | "prime", method?: "card" | "wallet", wallet_phone? }
// Grocery order:
//   POST { order_id: uuid, method?: "card" | "wallet", wallet_phone? }
//
// Replies { transaction_id, payment_url, amount_cents }.
//
// Secrets (Dashboard > Edge Functions > Secrets):
//   PAYMOB_API_KEY, PAYMOB_INTEGRATION_ID, PAYMOB_IFRAME_ID,
//   PAYMOB_WALLET_INTEGRATION_ID (optional), PAYMOB_BASE_URL (optional).

import { createClient } from "npm:@supabase/supabase-js@2";
import {
  egyptianWalletNumber,
  isPaymentMethod,
  isTier,
  json,
  paymobBaseUrl,
  PLAN_NAMES,
  PLAN_PRICES_CENTS,
} from "../_shared/paymob.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const reply = (body: unknown, status = 200) => json(body, status, CORS);

const PAYMENT_KEY_LIFETIME = 3600;

const CARD_INTEGRATION_ID =
  Number(Deno.env.get("PAYMOB_INTEGRATION_ID") || 6048858) || 6048858;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers: CORS });
  if (request.method !== "POST") return reply({ error: "POST only" }, 405);

  const body = await request.json().catch(() => ({}));
  const orderId = typeof body?.order_id === "string" ? body.order_id : null;
  const tier = body?.tier;
  const method = body?.method ?? "card";
  const isGrocery = orderId != null;

  if (!isGrocery && !isTier(tier)) return reply({ error: "invalid_tier" }, 400);
  if (isGrocery && tier != null) return reply({ error: "invalid_payload" }, 400);
  if (!isPaymentMethod(method)) return reply({ error: "invalid_method" }, 400);

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: { Authorization: request.headers.get("Authorization") ?? "" },
      },
    },
  );
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (!user) {
    return reply({
      error: "not_signed_in",
      details: request.headers.get("Authorization")
        ? `JWT rejected: ${authError?.message ?? "no user"}`
        : "No Authorization header was sent",
    }, 401);
  }

  const integrationId = method === "card"
    ? CARD_INTEGRATION_ID
    : Number(Deno.env.get("PAYMOB_WALLET_INTEGRATION_ID")) || null;
  const iframeId = Deno.env.get("PAYMOB_IFRAME_ID");
  const missingSecrets = [
    ...(Deno.env.get("PAYMOB_API_KEY") ? [] : ["PAYMOB_API_KEY"]),
    ...(integrationId ? [] : ["PAYMOB_WALLET_INTEGRATION_ID"]),
    ...(method === "card" && !iframeId ? ["PAYMOB_IFRAME_ID"] : []),
  ];
  if (missingSecrets.length > 0) {
    return reply({
      error: "method_unavailable",
      details: `Edge Function secrets not set: ${missingSecrets.join(", ")}`,
    }, 503);
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: profile } = await admin
    .from("profiles")
    .select("full_name, phone")
    .eq("id", user.id)
    .maybeSingle();

  const walletNumber = method === "wallet"
    ? egyptianWalletNumber(body?.wallet_phone ?? profile?.phone ?? user.phone)
    : null;
  if (method === "wallet" && !walletNumber) {
    return reply({ error: "wallet_phone_required" }, 400);
  }

  let amountCents: number;
  let itemName: string;
  let groceryOrderId: string | null = null;

  if (isGrocery) {
    const { data: order, error: orderError } = await admin
      .from("orders")
      .select("id, user_id, total_amount, payment_status")
      .eq("id", orderId)
      .maybeSingle();
    if (orderError || !order) {
      return reply({
        error: "order_not_found",
        details: orderError?.message ?? "no row",
      }, 404);
    }
    if (order.user_id !== user.id) {
      return reply({ error: "forbidden" }, 403);
    }
    const total = Number(order.total_amount);
    if (!Number.isFinite(total) || total <= 0) {
      return reply({ error: "invalid_order_amount" }, 400);
    }
    amountCents = Math.round(total * 100);
    itemName = `Safeer Market Order ${String(order.id).slice(0, 8)}`;
    groceryOrderId = order.id;
    await admin
      .from("orders")
      .update({
        payment_status: "pending",
        payment_method: "visa",
        updated_at: new Date().toISOString(),
      })
      .eq("id", groceryOrderId);
  } else {
    amountCents = PLAN_PRICES_CENTS[tier];
    itemName = PLAN_NAMES[tier];
  }

  const { data: transaction, error: insertError } = await admin
    .from("payment_transactions")
    .insert({
      user_id: user.id,
      amount: amountCents / 100,
      currency: "EGP",
      tier: isGrocery ? null : tier,
      order_id: groceryOrderId,
      status: "pending",
      payment_method: method,
    })
    .select("id")
    .single();
  if (insertError || !transaction) {
    console.error("payment_transactions insert failed", insertError);
    return reply({
      error: "server_error",
      details: `payment_transactions insert failed: ${
        insertError?.message ?? "no row returned"
      } (${insertError?.code ?? "?"})`,
    }, 500);
  }

  const markFailed = () =>
    admin
      .from("payment_transactions")
      .update({ status: "failed", updated_at: new Date().toISOString() })
      .eq("id", transaction.id);

  const paymobFailure = async (step: string, response: Response) => {
    const errorText = await response.text();
    console.error(
      `Paymob ${step} for ${transaction.id} answered ${response.status}: ${errorText}`,
    );
    await markFailed();
    return new Response(
      JSON.stringify({
        error: "paymob_error",
        details: errorText,
        status: response.status,
        step,
        integration_id: integrationId,
      }),
      { status: 502, headers: { "Content-Type": "application/json", ...CORS } },
    );
  };

  const post = (path: string, body: Record<string, unknown>) =>
    fetch(`${paymobBaseUrl()}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

  try {
    const authResponse = await post("/api/auth/tokens", {
      api_key: Deno.env.get("PAYMOB_API_KEY"),
    });
    if (!authResponse.ok) return paymobFailure("auth", authResponse);
    const { token } = await authResponse.json();

    const orderResponse = await post("/api/ecommerce/orders", {
      auth_token: token,
      delivery_needed: false,
      amount_cents: amountCents,
      currency: "EGP",
      merchant_order_id: transaction.id,
      items: [{
        name: itemName,
        amount_cents: amountCents,
        quantity: 1,
        description: itemName,
      }],
    });
    if (!orderResponse.ok) return paymobFailure("order", orderResponse);
    const order = await orderResponse.json();
    await admin
      .from("payment_transactions")
      .update({
        paymob_order_id: String(order.id),
        updated_at: new Date().toISOString(),
      })
      .eq("id", transaction.id);

    const [firstName, ...rest] = (profile?.full_name ?? "").trim().split(/\s+/);
    const keyResponse = await post("/api/acceptance/payment_keys", {
      auth_token: token,
      amount_cents: amountCents,
      expiration: PAYMENT_KEY_LIFETIME,
      order_id: order.id,
      currency: "EGP",
      integration_id: integrationId,
      lock_order_when_paid: true,
      billing_data: {
        first_name: firstName || "Safeer",
        last_name: rest.join(" ") || "Customer",
        email: user.email || "NA",
        phone_number: walletNumber ?? profile?.phone ?? user.phone ?? "NA",
        apartment: "NA",
        floor: "NA",
        street: "NA",
        building: "NA",
        shipping_method: "NA",
        postal_code: "NA",
        city: "NA",
        country: "EG",
        state: "NA",
      },
    });
    if (!keyResponse.ok) return paymobFailure("payment_key", keyResponse);
    const { token: paymentToken } = await keyResponse.json();

    let paymentUrl: string;
    if (method === "card") {
      paymentUrl = `${paymobBaseUrl()}/api/acceptance/iframes/${iframeId}` +
        `?payment_token=${encodeURIComponent(paymentToken)}`;
    } else {
      const payResponse = await post("/api/acceptance/payments/pay", {
        source: { identifier: walletNumber, subtype: "WALLET" },
        payment_token: paymentToken,
      });
      if (!payResponse.ok) return paymobFailure("wallet_pay", payResponse);
      const pay = await payResponse.json();
      paymentUrl = pay.redirect_url || pay.iframe_redirection_url;
      if (!paymentUrl) {
        await markFailed();
        return reply({
          error: "paymob_error",
          details: `No redirect_url from Paymob: ${JSON.stringify(pay)}`,
          status: payResponse.status,
          step: "wallet_pay",
        }, 502);
      }
    }

    return reply({
      transaction_id: transaction.id,
      payment_url: paymentUrl,
      amount_cents: amountCents,
      order_id: groceryOrderId,
    });
  } catch (error) {
    console.error(`Paymob checkout for ${transaction.id} failed`, error);
    await markFailed();
    return reply({
      error: "paymob_error",
      details: error instanceof Error
        ? `${error.name}: ${error.message}`
        : String(error),
      status: 0,
    }, 502);
  }
});
