// Paymob callbacks for subscription payments. Set this function's URL as
// both callbacks of every integration used (Paymob dashboard > Developers >
// Payment Integrations > Edit):
//   * Transaction processed callback (POST, server to server): the source
//     of truth. Settles the payment and activates the plan.
//   * Transaction response callback (GET, the customer's browser): settles
//     too, in case it arrives first, then sends the customer back to the app
//     at APP_RETURN_URL?status=…&transaction_id=….
// Both are signed: nothing is applied unless the HMAC checks out.
//
// Paymob sends no Supabase JWT, so deploy with:
//   supabase functions deploy paymob-webhook --no-verify-jwt
//
// Secrets:
//   PAYMOB_HMAC_SECRET   Paymob dashboard > Settings > Account info > HMAC.
//   APP_RETURN_URL       Optional, default
//                        io.supabase.safeermarket://payment-result
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.

import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  callbackHmacValues,
  json,
  paymobHmac,
  redirectHmacValues,
  sameSignature,
} from "../_shared/paymob.ts";

const appReturnUrl = () =>
  Deno.env.get("APP_RETURN_URL") ?? "io.supabase.safeermarket://payment-result";

const truthy = (value: unknown) => value === true || value === "true";

interface Outcome {
  transaction_id?: string;
  status: "pending" | "success" | "failed" | "unknown_order";
}

async function settle(
  admin: SupabaseClient,
  payment: {
    orderId: unknown;
    transactionId: unknown;
    amountCents: unknown;
    success: unknown;
    pending: unknown;
  },
): Promise<Outcome> {
  const { data, error } = await admin.rpc("settle_paymob_payment", {
    p_paymob_order_id: String(payment.orderId ?? ""),
    p_paymob_transaction_id: String(payment.transactionId ?? ""),
    p_amount_cents: Number(payment.amountCents),
    p_success: truthy(payment.success),
    p_pending: truthy(payment.pending),
  });
  if (error) throw new Error(`settle_paymob_payment: ${error.message}`);
  return data as Outcome;
}

Deno.serve(async (request) => {
  const url = new URL(request.url);
  const secret = Deno.env.get("PAYMOB_HMAC_SECRET");
  if (!secret) {
    console.error("PAYMOB_HMAC_SECRET is not set");
    return json({ error: "not_configured" }, 500);
  }
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Transaction processed callback.
  if (request.method === "POST") {
    const body = await request.json().catch(() => null);
    const obj = body?.obj;
    // Paymob also posts other event types (e.g. TOKEN); nothing to do.
    if (body?.type !== "TRANSACTION" || !obj) return json({ ignored: true });

    const received = url.searchParams.get("hmac") ?? body?.hmac ?? "";
    const expected = await paymobHmac(callbackHmacValues(obj), secret);
    if (!sameSignature(expected, received)) {
      console.warn(`Rejected Paymob callback for order ${obj.order?.id}: bad HMAC`);
      return json({ error: "invalid_hmac" }, 401);
    }

    // Refunds and voids arrive as transactions too; they never activate.
    if (truthy(obj.is_refunded) || truthy(obj.is_voided)) {
      return json({ ignored: true });
    }

    try {
      const outcome = await settle(admin, {
        orderId: obj.order?.id,
        transactionId: obj.id,
        amountCents: obj.amount_cents,
        success: obj.success,
        pending: obj.pending,
      });
      return json(outcome);
    } catch (error) {
      // A non-2xx makes Paymob retry the callback later.
      console.error(error);
      return json({ error: "settle_failed" }, 500);
    }
  }

  // Transaction response callback: the customer's browser, after paying.
  if (request.method === "GET") {
    const params = url.searchParams;
    const returnTo = new URL(appReturnUrl());
    const merchantOrderId = params.get("merchant_order_id");
    if (merchantOrderId) returnTo.searchParams.set("transaction_id", merchantOrderId);

    const expected = await paymobHmac(redirectHmacValues(params), secret);
    let status: string = "unverified";
    if (sameSignature(expected, params.get("hmac") ?? "")) {
      try {
        const outcome = truthy(params.get("is_refunded")) ||
            truthy(params.get("is_voided"))
          ? { status: "failed" as const }
          : await settle(admin, {
            orderId: params.get("order"),
            transactionId: params.get("id"),
            amountCents: params.get("amount_cents"),
            success: params.get("success"),
            pending: params.get("pending"),
          });
        status = outcome.status;
        if (outcome.transaction_id) {
          returnTo.searchParams.set("transaction_id", outcome.transaction_id);
        }
      } catch (error) {
        // The processed callback will settle it; the app checks the status.
        console.error(error);
        status = "pending";
      }
    } else {
      console.warn("Paymob redirect with a bad HMAC; app will check the status");
    }
    returnTo.searchParams.set("status", status);

    return new Response(null, {
      status: 302,
      headers: { Location: returnTo.toString() },
    });
  }

  return json({ error: "method_not_allowed" }, 405);
});
