// deno test --allow-env supabase/functions/_shared/paymob_test.ts

import {
  callbackHmacValues,
  egyptianWalletNumber,
  paymobHmac,
  PaymobError,
  paymobPost,
  redirectHmacValues,
  sameSignature,
} from "./paymob.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

const SECRET = "test-secret";
// HMAC-SHA512 of the fields below, computed independently (Python hmac).
const EXPECTED =
  "d31f61e97350a0d9c402f8962023b324f5f0e4d657769249230159061661e245" +
  "c80b6b484ec793d3b2ad009a3c721f2c42113c37199fe7f188bf57ffb8807d2f";

const callbackObj = {
  amount_cents: 18000,
  created_at: "2026-11-07T22:00:00.000000",
  currency: "EGP",
  error_occured: false,
  has_parent_transaction: false,
  id: 123456,
  integration_id: 4567,
  is_3d_secure: true,
  is_auth: false,
  is_capture: false,
  is_refunded: false,
  is_standalone_payment: true,
  is_voided: false,
  order: { id: 987654, merchant_order_id: "tx-1" },
  owner: 1111,
  pending: false,
  source_data: { pan: "2346", sub_type: "MasterCard", type: "card" },
  success: true,
};

Deno.test("signs a transaction processed callback like Paymob", async () => {
  assertEquals(await paymobHmac(callbackHmacValues(callbackObj), SECRET), EXPECTED);
});

Deno.test("signs the browser redirect the same way", async () => {
  const params = new URLSearchParams({
    amount_cents: "18000",
    created_at: "2026-11-07T22:00:00.000000",
    currency: "EGP",
    error_occured: "false",
    has_parent_transaction: "false",
    id: "123456",
    integration_id: "4567",
    is_3d_secure: "true",
    is_auth: "false",
    is_capture: "false",
    is_refunded: "false",
    is_standalone_payment: "true",
    is_voided: "false",
    order: "987654",
    owner: "1111",
    pending: "false",
    "source_data.pan": "2346",
    "source_data.sub_type": "MasterCard",
    "source_data.type": "card",
    success: "true",
    merchant_order_id: "tx-1",
  });
  assertEquals(await paymobHmac(redirectHmacValues(params), SECRET), EXPECTED);
});

Deno.test("a tampered amount or a wrong secret fails the check", async () => {
  const tampered = await paymobHmac(
    callbackHmacValues({ ...callbackObj, amount_cents: 100 }),
    SECRET,
  );
  assertEquals(sameSignature(tampered, EXPECTED), false);
  assertEquals(
    sameSignature(
      await paymobHmac(callbackHmacValues(callbackObj), "other"),
      EXPECTED,
    ),
    false,
  );
  assertEquals(sameSignature(EXPECTED, EXPECTED.toUpperCase()), true);
  assertEquals(sameSignature(EXPECTED, ""), false);
});

Deno.test("a refused Paymob call keeps Paymob's raw answer", async () => {
  const realFetch = globalThis.fetch;
  try {
    for (const [answer, status, body] of [
      [() => new Response('{"detail":"incorrect credentials"}', { status: 403 }),
        403, '{"detail":"incorrect credentials"}'],
      [() => Promise.reject(new TypeError("dns error")), 0,
        "fetch failed: TypeError: dns error"],
      [() => new Response("<html>gateway</html>", { status: 200 }), 200,
        "not JSON: <html>gateway</html>"],
    ] as const) {
      globalThis.fetch = (() => answer()) as typeof fetch;
      let caught: unknown;
      try {
        await paymobPost("/api/auth/tokens", { api_key: "k" });
      } catch (error) {
        caught = error;
      }
      if (!(caught instanceof PaymobError)) throw new Error(`no PaymobError`);
      assertEquals(caught.path, "/api/auth/tokens");
      assertEquals(caught.status, status);
      assertEquals(caught.body, body);
    }
  } finally {
    globalThis.fetch = realFetch;
  }
});

Deno.test("normalises Egyptian wallet numbers", () => {
  assertEquals(egyptianWalletNumber("01012345678"), "01012345678");
  assertEquals(egyptianWalletNumber("+20 101 234 5678"), "01012345678");
  assertEquals(egyptianWalletNumber("201012345678"), "01012345678");
  assertEquals(egyptianWalletNumber("٠١٠١٢٣٤٥٦٧٨"), "01012345678");
  assertEquals(egyptianWalletNumber("01312345678"), null);
  assertEquals(egyptianWalletNumber("12345"), null);
  assertEquals(egyptianWalletNumber(undefined), null);
});
