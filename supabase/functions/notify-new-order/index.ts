import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const ONESIGNAL_API_URL = "https://api.onesignal.com/notifications";
const SUBSCRIPTION_BATCH_SIZE = 20_000;
const MAX_SEND_ATTEMPTS = 3;
const WEBHOOK_SECRET_HEADER = "x-mediasis-webhook-secret";
const RENDER_CACHE_BUCKET = "receipt-print-renders";
const RENDER_VERSION = "v2-market";

type JsonRecord = Record<string, unknown>;
type MediasisSupabaseClient = SupabaseClient<any, any, any, any, any>;

interface DatabaseWebhookPayload {
  type: string;
  table: string;
  schema: string;
  record: JsonRecord | null;
  old_record: JsonRecord | null;
}

interface OrderRecord {
  order_id: string;
  human_order_number: number | string;
  business_location_id: string;
  delivery_method: string | null;
  order_status: string | null;
  products_payment_status: string | null;
  products_payment_intent_id: string | null;
  delivery_payment_status: string | null;
  uber_delivery_id: string | null;
  tracking_link: string | null;
}

interface OneSignalResponse {
  id?: string;
  errors?: unknown;
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

function jsonResponse(body: JsonRecord, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required secret: ${name}`);
  return value;
}

function getSupabaseSecretKey(): string {
  const legacyKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (legacyKey) return legacyKey;

  const singleSecretKey = Deno.env.get("SUPABASE_SECRET_KEY")?.trim();
  if (singleSecretKey) return singleSecretKey;

  const secretKeysJson = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (secretKeysJson) {
    const secretKeys = JSON.parse(secretKeysJson) as Record<string, string>;
    const defaultKey = secretKeys.default?.trim();
    if (defaultKey) return defaultKey;
  }

  throw new Error("Missing Supabase secret/service-role key");
}

function constantTimeEqual(left: string, right: string): boolean {
  const leftBytes = new TextEncoder().encode(left);
  const rightBytes = new TextEncoder().encode(right);
  const maxLength = Math.max(leftBytes.length, rightBytes.length);
  let difference = leftBytes.length ^ rightBytes.length;

  for (let index = 0; index < maxLength; index += 1) {
    difference |= (leftBytes[index] ?? 0) ^ (rightBytes[index] ?? 0);
  }

  return difference === 0;
}

function base64Url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

async function createPrintAuthorization(order: OrderRecord): Promise<string> {
  const payload = base64Url(
    new TextEncoder().encode(JSON.stringify({
      order_id: order.order_id,
      business_location_id: order.business_location_id,
      exp: Math.floor(Date.now() / 1000) + 10 * 60,
    })),
  );
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(requiredEnv("BACKGROUND_PRINT_SIGNING_SECRET")),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload)),
  );
  return `${payload}.${base64Url(signature)}`;
}

function nullableString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function webhookOrder(record: JsonRecord | null): OrderRecord | null {
  if (!record) return null;

  const orderId = nullableString(record.order_id);
  const businessLocationId = nullableString(record.business_location_id);
  if (!orderId || !businessLocationId) return null;

  const humanOrderNumber = record.human_order_number;
  if (
    typeof humanOrderNumber !== "number" &&
    typeof humanOrderNumber !== "string"
  ) {
    return null;
  }

  return {
    order_id: orderId,
    human_order_number: humanOrderNumber,
    business_location_id: businessLocationId,
    delivery_method: nullableString(record.delivery_method),
    order_status: nullableString(record.order_status),
    products_payment_status: nullableString(record.products_payment_status),
    products_payment_intent_id: nullableString(
      record.products_payment_intent_id,
    ),
    delivery_payment_status: nullableString(record.delivery_payment_status),
    uber_delivery_id: nullableString(record.uber_delivery_id),
    tracking_link: nullableString(record.tracking_link),
  };
}

async function isOrderPaid(
  supabase: MediasisSupabaseClient,
  order: OrderRecord,
): Promise<boolean> {
  const { data, error } = await supabase.rpc("is_order_paid", {
    p_order_status: order.order_status,
    p_products_payment_status: order.products_payment_status,
    p_products_payment_intent_id: order.products_payment_intent_id,
    p_delivery_payment_status: order.delivery_payment_status,
    p_delivery_method_id: order.delivery_method,
    p_tracking_link: order.tracking_link,
    p_uber_delivery_id: order.uber_delivery_id,
  });

  if (error) {
    throw new Error(`Could not determine payment state: ${error.message}`);
  }

  return data === true;
}

async function preRenderVisualReceipts(
  supabase: MediasisSupabaseClient,
  order: OrderRecord,
): Promise<void> {
  const { data, error } = await supabase.rpc(
    "get_receipt_print_data_for_background",
    {
      p_order_id: order.order_id,
      p_business_location_id: order.business_location_id,
    },
  );
  const payload = data as {
    success?: boolean;
    data?: {
      order?: { receipt_url?: unknown };
      business?: { domain?: unknown };
    };
    message?: string;
  } | null;
  if (error || !payload?.success || !payload.data) {
    throw new Error(error?.message ?? payload?.message ?? "Receipt unavailable");
  }
  const market = (payload.data as unknown as {market?: Record<string, unknown>}).market;
  if (!market?.currency_code || !market.locale || !market.timezone) throw new Error("MARKET_SETTINGS_MISSING");
  const marketKey = [market.currency_code, market.locale, market.timezone, market.updated_at]
    .map((value) => String(value ?? "").replace(/[^a-zA-Z0-9_-]/g, "_")).join("-");
  const receiptUrl = nullableString(payload.data.order?.receipt_url);
  const businessDomain = nullableString(payload.data.business?.domain);
  if (!receiptUrl && !businessDomain) throw new Error("Receipt URL unavailable");

  await Promise.all(["mm58", "mm80"].map(async (paperWidth) => {
    const response = await fetch(
      new URL(
        "/api/internal/orders/receipt-print-bytes",
        requiredEnv("DASHBOARD_API_BASE_URL"),
      ),
      {
        method: "POST",
        signal: AbortSignal.timeout(13_000),
        headers: {
          "Content-Type": "application/json",
          "x-mediasis-render-secret": requiredEnv(
            "RECEIPT_RENDER_INTERNAL_SECRET",
          ),
        },
        body: JSON.stringify({
          receipt_url: receiptUrl ?? "",
          business_domain: businessDomain,
          order_id: order.order_id,
          paper_width: paperWidth,
          supports_cutter: false,
        }),
      },
    );
    if (!response.ok) {
      throw new Error(`Could not pre-render ${paperWidth} receipt`);
    }
    const bytes = new Uint8Array(await response.arrayBuffer());
    const cachePath =
      `${order.order_id}/${RENDER_VERSION}/${marketKey}/${paperWidth}.escpos`;
    const { error: uploadError } = await supabase.storage
      .from(RENDER_CACHE_BUCKET)
      .upload(cachePath, bytes, {
        contentType: "application/vnd.mediasis.escpos",
        upsert: true,
      });
    if (uploadError) throw uploadError;
  }));
}

async function deterministicUuid(
  orderId: string,
  batchIndex: number,
): Promise<string> {
  if (batchIndex === 0) return orderId;

  const digest = new Uint8Array(
    await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(`${orderId}:${batchIndex}`),
    ),
  ).slice(0, 16);

  digest[6] = (digest[6] & 0x0f) | 0x50;
  digest[8] = (digest[8] & 0x3f) | 0x80;

  const hex = Array.from(digest, (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");

  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20),
  ].join("-");
}

function retryDelay(response: Response, attempt: number): number {
  const retryAfter = Number(response.headers.get("Retry-After"));
  if (Number.isFinite(retryAfter) && retryAfter > 0) {
    return Math.min(retryAfter * 1000, 10_000);
  }

  return 500 * (2 ** attempt);
}

async function sendOneSignalBatch(
  restApiKey: string,
  appId: string,
  order: OrderRecord,
  subscriptionIds: string[],
  batchIndex: number,
): Promise<string | null> {
  const idempotencyKey = await deterministicUuid(order.order_id, batchIndex);
  const printAuthorization = await createPrintAuthorization(order);
  const printEndpoint = `${requiredEnv("SUPABASE_URL")}/functions/v1/background-print-receipt`;
  let lastError = "OneSignal request failed";

  for (let attempt = 0; attempt < MAX_SEND_ATTEMPTS; attempt += 1) {
    const response = await fetch(ONESIGNAL_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Key ${restApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        app_id: appId,
        include_subscription_ids: subscriptionIds,
        idempotency_key: idempotencyKey,
        headings: {
          en: "New order",
          es: "Nuevo pedido",
        },
        contents: {
          en: `Order #${order.human_order_number} is ready to prepare.`,
          es: `Pedido #${order.human_order_number} listo para preparar.`,
        },
        data: {
          type: "new_order",
          payload_version: 2,
          order_id: order.order_id,
          business_location_id: order.business_location_id,
          print_authorization: printAuthorization,
          print_endpoint: printEndpoint,
        },
        content_available: true,
        mutable_content: true,
        priority: 10,
        ios_interruption_level: "time_sensitive",
      }),
    });

    const responseBody = await response.text();
    let parsedBody: OneSignalResponse = {};
    try {
      parsedBody = responseBody
        ? JSON.parse(responseBody) as OneSignalResponse
        : {};
    } catch {
      parsedBody = {};
    }

    if (response.ok) return parsedBody.id ?? null;

    lastError =
      `OneSignal ${response.status}: ${responseBody.slice(0, 500)}`;
    const retryable = response.status === 429 || response.status >= 500;
    if (!retryable || attempt === MAX_SEND_ATTEMPTS - 1) break;

    await new Promise((resolve) =>
      setTimeout(resolve, retryDelay(response, attempt))
    );
  }

  throw new Error(lastError);
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse({ success: false, message: "Method not allowed" }, 405);
  }

  let orderId: string | null = null;
  let claimAcquired = false;

  try {
    const expectedWebhookSecret = requiredEnv(
      "ONESIGNAL_NEW_ORDER_WEBHOOK_SECRET",
    );
    const providedWebhookSecret =
      request.headers.get(WEBHOOK_SECRET_HEADER) ?? "";

    if (!constantTimeEqual(providedWebhookSecret, expectedWebhookSecret)) {
      throw new HttpError(401, "Invalid webhook secret");
    }

    const payload = await request.json() as DatabaseWebhookPayload;
    if (
      payload.type !== "UPDATE" ||
      payload.schema !== "mediasis" ||
      payload.table !== "orders"
    ) {
      return jsonResponse({
        success: true,
        skipped: "Only mediasis.orders UPDATE events are accepted",
      });
    }

    const eventOrder = webhookOrder(payload.record);
    const oldOrder = webhookOrder(payload.old_record);
    if (!eventOrder || !oldOrder || eventOrder.order_id !== oldOrder.order_id) {
      throw new HttpError(400, "Webhook order payload is incomplete");
    }
    orderId = eventOrder.order_id;

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const supabase = createClient(supabaseUrl, getSupabaseSecretKey(), {
      db: { schema: "mediasis" },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: currentOrderData, error: orderError } = await supabase
      .from("orders")
      .select(`
        order_id,
        human_order_number,
        business_location_id,
        delivery_method,
        order_status,
        products_payment_status,
        products_payment_intent_id,
        delivery_payment_status,
        uber_delivery_id,
        tracking_link
      `)
      .eq("order_id", orderId)
      .maybeSingle();

    if (orderError) {
      throw new Error(`Could not load order: ${orderError.message}`);
    }

    const currentOrder = webhookOrder(currentOrderData as JsonRecord | null);
    if (!currentOrder) {
      return jsonResponse({ success: true, skipped: "Order no longer exists" });
    }

    const [wasPaid, isPaid] = await Promise.all([
      isOrderPaid(supabase, oldOrder),
      isOrderPaid(supabase, currentOrder),
    ]);

    if (wasPaid || !isPaid) {
      return jsonResponse({
        success: true,
        skipped: wasPaid
          ? "Order was already paid before this update"
          : "Order is not paid yet",
      });
    }

    const { data: claimed, error: claimError } = await supabase.rpc(
      "claim_new_order_push_delivery",
      {
        p_order_id: currentOrder.order_id,
        p_business_location_id: currentOrder.business_location_id,
      },
    );

    if (claimError) {
      throw new Error(`Could not claim notification: ${claimError.message}`);
    }
    if (claimed !== true) {
      return jsonResponse({
        success: true,
        skipped: "Notification was already claimed or delivered",
      });
    }
    claimAcquired = true;

    const { data: subscriptions, error: subscriptionsError } = await supabase
      .from("new_order_push_subscriptions")
      .select("subscription_id")
      .eq("business_location_id", currentOrder.business_location_id)
      .eq("enabled", true);

    if (subscriptionsError) {
      throw new Error(
        `Could not load subscriptions: ${subscriptionsError.message}`,
      );
    }

    const subscriptionIds = (subscriptions ?? [])
      .map((item) => nullableString(item.subscription_id))
      .filter((value): value is string => value !== null);

    if (subscriptionIds.length === 0) {
      const { error: completeError } = await supabase.rpc(
        "complete_new_order_push_delivery",
        {
          p_order_id: currentOrder.order_id,
          p_status: "no_subscribers",
          p_onesignal_message_ids: [],
        },
      );
      if (completeError) {
        throw new Error(
          `Could not complete notification: ${completeError.message}`,
        );
      }

      claimAcquired = false;
      return jsonResponse({
        success: true,
        skipped: "No active subscriptions for this location",
      });
    }

    const restApiKey = requiredEnv("ONESIGNAL_NEW_ORDER_REST_API_KEY");
    const appId = requiredEnv("ONESIGNAL_NEW_ORDER_APP_ID");
    const messageIds: string[] = [];

    try {
      await preRenderVisualReceipts(supabase, currentOrder);
    } catch (renderError) {
      console.error("Visual receipt pre-render failed", {
        orderId: currentOrder.order_id,
        message: renderError instanceof Error
          ? renderError.message
          : "Unknown render error",
      });
    }

    for (
      let offset = 0;
      offset < subscriptionIds.length;
      offset += SUBSCRIPTION_BATCH_SIZE
    ) {
      const batchIndex = Math.floor(offset / SUBSCRIPTION_BATCH_SIZE);
      const messageId = await sendOneSignalBatch(
        restApiKey,
        appId,
        currentOrder,
        subscriptionIds.slice(offset, offset + SUBSCRIPTION_BATCH_SIZE),
        batchIndex,
      );
      if (messageId) messageIds.push(messageId);
    }

    const { error: completeError } = await supabase.rpc(
      "complete_new_order_push_delivery",
      {
        p_order_id: currentOrder.order_id,
        p_status: "sent",
        p_onesignal_message_ids: messageIds,
      },
    );
    if (completeError) {
      throw new Error(
        `Notification sent but delivery log failed: ${completeError.message}`,
      );
    }

    claimAcquired = false;
    return jsonResponse({
      success: true,
      sent_to: subscriptionIds.length,
      onesignal_message_ids: messageIds,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    console.error("notify-new-order failed", { orderId, message });

    if (claimAcquired && orderId) {
      try {
        const supabase = createClient(
          requiredEnv("SUPABASE_URL"),
          getSupabaseSecretKey(),
          {
            db: { schema: "mediasis" },
            auth: { persistSession: false, autoRefreshToken: false },
          },
        );
        await supabase.rpc("release_new_order_push_delivery", {
          p_order_id: orderId,
          p_error: message,
        });
      } catch (releaseError) {
        console.error("Could not release notification claim", releaseError);
      }
    }

    const status = error instanceof HttpError ? error.status : 500;
    return jsonResponse({ success: false, message }, status);
  }
});
