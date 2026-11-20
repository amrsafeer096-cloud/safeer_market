// Paymob (Accept, Egypt) helpers shared by create-paymob-order and
// paymob-webhook.

export type Tier = "vip" | "prime";
export type PaymentMethod = "card" | "wallet";

/// What each plan costs, in piasters. The app shows the same prices on the
/// paywall, but only these are ever charged.
export const PLAN_PRICES_CENTS: Record<Tier, number> = {
  vip: 18000,
  prime: 9000,
};

export const PLAN_NAMES: Record<Tier, string> = {
  vip: "Safeer Pro (VIP) - 30 days",
  prime: "Safeer Prime - 30 days",
};

export const isTier = (value: unknown): value is Tier =>
  value === "vip" || value === "prime";

export const isPaymentMethod = (value: unknown): value is PaymentMethod =>
  value === "card" || value === "wallet";

export const paymobBaseUrl = () =>
  (Deno.env.get("PAYMOB_BASE_URL") ?? "https://accept.paymob.com").replace(
    /\/+$/,
    "",
  );

export const json = (body: unknown, status = 200, headers: HeadersInit = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });

/// A Paymob call that failed: [status] and [body] are Paymob's raw answer
/// (status 0 when no answer arrived).
export class PaymobError extends Error {
  constructor(
    readonly path: string,
    readonly status: number,
    readonly body: string,
  ) {
    super(`Paymob ${path} answered ${status}: ${body}`);
    this.name = "PaymobError";
  }
}

/// POSTs [body] to a Paymob API path and returns the JSON reply. Anything
/// but a 2xx with JSON throws a [PaymobError] carrying the raw response.
export async function paymobPost<T = Record<string, unknown>>(
  path: string,
  body: Record<string, unknown>,
): Promise<T> {
  const url = `${paymobBaseUrl()}${path}`;
  let response: Response;
  try {
    response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  } catch (error) {
    throw new PaymobError(path, 0, `fetch failed: ${String(error)}`);
  }
  const text = await response.text();
  if (!response.ok) throw new PaymobError(path, response.status, text);
  try {
    return JSON.parse(text) as T;
  } catch {
    throw new PaymobError(path, response.status, `not JSON: ${text}`);
  }
}

/// The transaction fields Paymob signs, in the order it concatenates them.
const HMAC_FIELDS = [
  "amount_cents",
  "created_at",
  "currency",
  "error_occured",
  "has_parent_transaction",
  "id",
  "integration_id",
  "is_3d_secure",
  "is_auth",
  "is_capture",
  "is_refunded",
  "is_standalone_payment",
  "is_voided",
  "order",
  "owner",
  "pending",
  "source_data.pan",
  "source_data.sub_type",
  "source_data.type",
  "success",
] as const;

type HmacField = (typeof HMAC_FIELDS)[number];

// deno-lint-ignore no-explicit-any
type PaymobTransaction = Record<string, any>;

/// HMAC_FIELDS read from a "Transaction processed" callback's `obj`.
export function callbackHmacValues(
  obj: PaymobTransaction,
): Record<HmacField, unknown> {
  return {
    amount_cents: obj.amount_cents,
    created_at: obj.created_at,
    currency: obj.currency,
    error_occured: obj.error_occured,
    has_parent_transaction: obj.has_parent_transaction,
    id: obj.id,
    integration_id: obj.integration_id,
    is_3d_secure: obj.is_3d_secure,
    is_auth: obj.is_auth,
    is_capture: obj.is_capture,
    is_refunded: obj.is_refunded,
    is_standalone_payment: obj.is_standalone_payment,
    is_voided: obj.is_voided,
    order: obj.order?.id,
    owner: obj.owner,
    pending: obj.pending,
    "source_data.pan": obj.source_data?.pan,
    "source_data.sub_type": obj.source_data?.sub_type,
    "source_data.type": obj.source_data?.type,
    success: obj.success,
  };
}

/// HMAC_FIELDS read from the "Transaction response" redirect's query string,
/// where Paymob sends them flat and already as text.
export function redirectHmacValues(
  params: URLSearchParams,
): Record<HmacField, unknown> {
  return Object.fromEntries(
    HMAC_FIELDS.map((field) => [field, params.get(field)]),
  ) as Record<HmacField, unknown>;
}

const asHmacText = (value: unknown) =>
  value === null || value === undefined ? "" : String(value);

/// Paymob's signature: HMAC-SHA512 over the concatenated HMAC_FIELDS
/// values, hex encoded. Booleans count as "true" / "false".
export async function paymobHmac(
  values: Record<HmacField, unknown>,
  secret: string,
): Promise<string> {
  const message = HMAC_FIELDS.map((field) => asHmacText(values[field])).join(
    "",
  );
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(message),
  );
  return Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

/// Compares two signatures without leaking where they differ.
export function sameSignature(expected: string, received: string): boolean {
  const a = new TextEncoder().encode(expected.toLowerCase());
  const b = new TextEncoder().encode(received.trim().toLowerCase());
  let diff = a.length ^ b.length;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    diff |= (a[i] ?? 0) ^ (b[i] ?? 0);
  }
  return diff === 0;
}

/// Egyptian mobile number as Paymob wallets expect it: 01XXXXXXXXX.
export function egyptianWalletNumber(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  let digits = raw
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[^\d]/g, "");
  if (digits.startsWith("0020")) digits = digits.slice(4);
  else if (digits.startsWith("20") && digits.length === 12) {
    digits = digits.slice(2);
  }
  if (digits.length === 10 && digits.startsWith("1")) digits = `0${digits}`;
  return /^01[0125]\d{8}$/.test(digits) ? digits : null;
}
