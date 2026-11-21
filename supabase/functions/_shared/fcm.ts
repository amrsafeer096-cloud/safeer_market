// Firebase Cloud Messaging HTTP v1 helpers shared by the push functions.
//
// Needs the FIREBASE_SERVICE_ACCOUNT secret: the Firebase service-account
// JSON (Project settings > Service accounts > Generate new private key),
// pasted whole.
//
// Every mobile payload must carry both a top-level `notification` block
// (so Android / iOS show a tray banner while the app is killed) and a
// `data` map (so the Flutter tap handler can deep-link).

import { importPKCS8, SignJWT } from "npm:jose@5";

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

export function serviceAccount(): ServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT is not set");
  return JSON.parse(raw);
}

let cached: { token: string; expiresAt: number } | null = null;

/** OAuth access token for FCM, reused until a minute before it expires. */
export async function googleAccessToken(
  account: ServiceAccount,
): Promise<string> {
  if (cached && cached.expiresAt - 60_000 > Date.now()) return cached.token;

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
  const body = await response.json();
  cached = {
    token: body.access_token,
    expiresAt: Date.now() + (body.expires_in ?? 3600) * 1000,
  };
  return cached.token;
}

export type SendResult =
  | { ok: true }
  | { ok: false; status: number; error: string; unregistered: boolean };

/** Sends one FCM v1 message (`{ token | topic, notification, ... }`). */
export async function sendFcmMessage(
  account: ServiceAccount,
  accessToken: string,
  message: Record<string, unknown>,
): Promise<SendResult> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    },
  );
  if (response.ok) return { ok: true };

  const error = await response.text();
  // Tokens of uninstalled apps, cleared browser data or signed-out devices.
  const unregistered = response.status === 404 ||
    error.includes("UNREGISTERED") ||
    (response.status === 400 &&
      error.includes("registration token is not a valid"));
  return { ok: false, status: response.status, error, unregistered };
}

/** Android options that wake the tray even when the app process is gone. */
export function androidPushConfig(options: {
  channelId: string;
  sound?: string;
  tag?: string;
  urgent?: boolean;
}): Record<string, unknown> {
  return {
    priority: "HIGH",
    ttl: options.urgent ? "1800s" : "86400s",
    notification: {
      channel_id: options.channelId,
      sound: options.sound ?? (options.urgent ? "order_chime" : "default"),
      default_vibrate_timings: true,
      visibility: "PUBLIC",
      ...(options.tag ? { tag: options.tag } : {}),
      notification_priority: options.urgent
        ? "PRIORITY_MAX"
        : "PRIORITY_HIGH",
    },
  };
}

/** APNs options: high priority alert + content-available for background wake. */
export function apnsPushConfig(options: {
  sound?: string;
  urgent?: boolean;
}): Record<string, unknown> {
  return {
    headers: {
      "apns-priority": "10",
      "apns-push-type": "alert",
    },
    payload: {
      aps: {
        sound: options.sound ??
          (options.urgent ? "order_chime.caf" : "default"),
        "content-available": 1,
      },
    },
  };
}
