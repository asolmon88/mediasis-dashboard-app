import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

type JsonRecord = Record<string, unknown>;
type MediasisSupabaseClient = SupabaseClient<any, any, any, any, any>;
const RENDER_CACHE_BUCKET = "receipt-print-renders";
const RENDER_VERSION = "v2-market";

function env(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required secret: ${name}`);
  return value;
}

async function withDeadline<T>(operation: Promise<T>, milliseconds: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      operation,
      new Promise<T>((_, reject) => {
        timer = setTimeout(
          () => reject(new Error("Visual receipt renderer timed out")),
          milliseconds,
        );
      }),
    ]);
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}

function decode64(value: string): Uint8Array {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
}

async function authorize(token: string): Promise<JsonRecord> {
  const [payload, signature, extra] = token.split(".");
  if (!payload || !signature || extra) throw new Error("Invalid authorization");
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(env("BACKGROUND_PRINT_SIGNING_SECRET")),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    "HMAC",
    key,
    decode64(signature) as BufferSource,
    new TextEncoder().encode(payload),
  );
  if (!valid) throw new Error("Invalid authorization");
  const decoded = JSON.parse(new TextDecoder().decode(decode64(payload))) as JsonRecord;
  if (Number(decoded.exp ?? 0) < Math.floor(Date.now() / 1000)) {
    throw new Error("Authorization expired");
  }
  return decoded;
}

const clean = (value: unknown) => `${value ?? ""}`
  .normalize("NFD")
  .replace(/[\u0300-\u036f]/g, "")
  .replace(/[\u2018\u2019]/g, "'")
  .replace(/[\u201c\u201d]/g, '"')
  .replace(/[\u2013\u2014]/g, "-")
  .replace(/\u2026/g, ".")
  .replace(/[^\x20-\x7e]/g, " ");
const numeric = (value: unknown) => Number.isFinite(Number(value)) ? Number(value) : 0;


function object(value: unknown): JsonRecord {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as JsonRecord;
  }
  if (typeof value === "string" && value.trim()) {
    try {
      const decoded = JSON.parse(value);
      return decoded && typeof decoded === "object" && !Array.isArray(decoded)
        ? decoded as JsonRecord
        : {};
    } catch (_) {
      return {};
    }
  }
  return {};
}

function objects(value: unknown): JsonRecord[] {
  if (Array.isArray(value)) return value.map(object);
  if (typeof value === "string" && value.trim()) {
    try {
      const decoded = JSON.parse(value);
      return Array.isArray(decoded) ? decoded.map(object) : [];
    } catch (_) {
      return [];
    }
  }
  return [];
}

function receiptBytes(data: JsonRecord, paper: string, cutter: boolean): Uint8Array {
  const market = object(data.market);
  if (!market.currency_code || !market.locale || !market.timezone) throw new Error("MARKET_SETTINGS_MISSING");
  const money = (value: unknown) => {
    const currency = String(market.currency_code);
    const amount = numeric(value);
    const decimals = currency === "CRC" && Number.isInteger(amount) ? 0 : 2;
    return clean(`${currency} ${new Intl.NumberFormat(String(market.locale), {
      minimumFractionDigits: decimals, maximumFractionDigits: decimals,
    }).format(amount)}`);
  };
  const label = (es: string, en: string) => String(market.locale).startsWith("en") ? en : es;
function choiceLabel(value: unknown): string {
  const choice = object(value);
  const name = clean(choice.choice);
  if (!name) return "";
  const quantity = numeric(choice.quantity);
  const price = numeric(choice.price);
  return `${name}${quantity > 0 ? ` (${Math.trunc(quantity)})` : ""}${
    price > 0 ? ` +${money(price)}` : ""
  }`;
}

function productOptionLines(value: unknown): string[] {
  const options = object(value);
  const lines: string[] = [];
  for (const type of ["selection", "checkbox"]) {
    for (const entry of objects(options[type])) {
      const name = clean(entry.name);
      const choices = type === "selection"
        ? [object(entry.choice)]
        : objects(entry.choices);
      for (const choice of choices) {
        const label = choiceLabel(choice);
        if (name && label) lines.push(`${name}: ${label}`);
      }
    }
  }
  for (const type of ["text", "number", "date", "media"]) {
    for (const entry of objects(options[type])) {
      const name = clean(entry.name);
      const value = clean(entry.value);
      if (name && value) lines.push(`${name}: ${value}`);
    }
  }
  return lines;
}

function wrap(value: string, columns: number): string[] {
  const lines: string[] = [];
  let current = "";
  for (const word of clean(value).trim().split(/\s+/)) {
    if (!word) continue;
    if (word.length > columns) {
      if (current) { lines.push(current); current = ""; }
      for (let start = 0; start < word.length; start += columns) {
        lines.push(word.slice(start, start + columns));
      }
      continue;
    }
    const next = current ? `${current} ${word}` : word;
    if (next.length <= columns) current = next;
    else { if (current) lines.push(current); current = word; }
  }
  if (current) lines.push(current);
  return lines;
}

function twoColumns(left: string, right: string, columns: number): string[] {
  const safeLeft = clean(left);
  const safeRight = clean(right);
  const leftWidth = Math.max(8, columns - safeRight.length - 1);
  const lines = wrap(safeLeft, leftWidth);
  if (!lines.length) return [safeRight.padStart(columns)];
  const last = lines.at(-1) ?? "";
  if (last.length + safeRight.length + 1 <= columns) {
    lines[lines.length - 1] = `${last}${" ".repeat(columns - last.length - safeRight.length)}${safeRight}`;
  } else {
    lines.push(safeRight.padStart(columns));
  }
  return lines;
}

function dateTime(value: unknown): string {
  const date = new Date(clean(value));
  if (Number.isNaN(date.getTime())) return label("Pendiente", "Pending");
  return clean(new Intl.DateTimeFormat(String(market.locale), {
    timeZone: String(market.timezone),
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date));
}

function additionalDetailLines(value: unknown): string[] {
  const lines: string[] = [];
  for (const entry of objects(value)) {
    const type = clean(entry.type);
    const question = clean(entry.question);
    if (type === "text") {
      const text = clean(entry.text);
      if (text) lines.push(text);
    } else if (type === "select") {
      const label = choiceLabel(entry.value);
      if (question && label) lines.push(`${question}: ${label}`);
    } else if (type === "checkbox") {
      for (const choice of objects(entry.value)) {
        const label = choiceLabel(choice);
        if (question && label) lines.push(`${question}: ${label}`);
      }
    } else {
      const answer = clean(entry.value);
      if (question && answer) lines.push(`${question}: ${answer}`);
    }
  }
  return lines;
}

  const columns = paper === "mm58" ? 32 : 40;
  const business = (data.business ?? {}) as JsonRecord;
  const order = (data.order ?? {}) as JsonRecord;
  const customer = (data.customer ?? {}) as JsonRecord;
  const items = Array.isArray(data.items) ? data.items as JsonRecord[] : [];
  const bytes: number[] = [0x1b, 0x40, 0x1b, 0x4d, 0x00];
  const add = (value = "", bold = false) => {
    bytes.push(0x1b, 0x45, bold ? 0x01 : 0x00);
    bytes.push(...new TextEncoder().encode(`${value}\n`));
  };
  const center = (value: string, bold = false) => add(
    clean(value).slice(0, columns).padStart(
      Math.floor((columns + clean(value).slice(0, columns).length) / 2),
    ),
    bold,
  );
  const section = (title: string, lines: string[]) => {
    const visible = lines.map(clean).filter(Boolean);
    if (!visible.length) return;
    add("-".repeat(columns)); add(title); add();
    visible.forEach((line) =>
      wrap(line, columns).forEach((wrapped) => add(wrapped))
    );
  };
  const businessName = clean(business.name) || "Mediasis";
  const locationName = clean(order.business_location_name);
  wrap(locationName ? `${businessName} - ${locationName}` : businessName, columns)
    .forEach((line) => center(line));
  if (clean(business.domain)) center(clean(business.domain));
  if (clean(business.phone_number)) center(clean(business.phone_number));
  add(); center(label("RECIBO", "RECEIPT"), true);
  center(`#${clean(order.human_order_number) || clean(order.order_id)}`, true);
  add("-".repeat(columns));
  add(label("Fecha", "Date")); add(dateTime(order.created_at)); add();
  add(label("Metodo de pago", "Payment method")); add(clean(order.payment_method_name) || label("Pendiente", "Pending")); add();
  add(label("Servicio", "Service")); add(clean(order.delivery_method_name) || label("No definido", "Not specified")); add();
  add(label("Estado", "Status")); add(clean(order.order_status) || label("Pendiente", "Pending")); add();
  add("-".repeat(columns)); add(label("Items", "Items")); add();
  for (const item of items) {
    twoColumns(
      `${numeric(item.quantity) || 1}x ${clean(item.name) || label("Producto", "Product")}`,
      money(item.display_unit_price),
      columns,
    ).forEach((line) => add(line, true));
    add(money(item.line_total).padStart(columns), true);
    if (clean(item.variant_name) && item.variant_name !== item.name) {
      add(`  ${clean(item.variant_name)}`, true);
    }
    for (const option of productOptionLines(item.options)) {
      wrap(`  - ${option}`, columns).forEach((line) => add(line, true));
    }
    add();
  }
  add("-".repeat(columns)); add(label("Totales", "Totals")); add();
  const products = numeric(order.products_price);
  const discount = numeric(order.discount_amount);
  twoColumns(label("Productos", "Products"), money(products), columns)
    .forEach((line) => add(line));
  if (discount > 0) {
    const code = clean(order.discount_code);
    twoColumns(code ? `${label("Descuento", "Discount")} ${code}` : label("Descuento", "Discount"), money(-discount), columns)
      .forEach((line) => add(line));
  }
  add("-".repeat(columns));
  twoColumns("Total", money(Math.max(0, products - discount)), columns)
    .forEach((line) => add(line, true));

  const cashbackEarned = numeric(order.cashback_earned_minor) / 100;
  if (cashbackEarned > 0) {
    const status = clean(order.cashback_earning_status);
    const cashbackLabel = status === "available" ? label("Cashback acumulado", "Cashback earned")
      : status === "pending" ? label("Pendiente hasta entregar", "Pending until delivery") : label("Cashback revertido", "Cashback reversed");
    section("Cashback", twoColumns(cashbackLabel, money(cashbackEarned), columns));
  }
  section(label("Cliente", "Customer"), [
    clean(customer.full_name),
    clean(customer.phone),
    clean(customer.email),
  ]);

  const details = additionalDetailLines(data.additional_details);
  if (clean(order.delivery_note)) details.push(`${label("Nota de entrega", "Delivery note")}: ${clean(order.delivery_note)}`);
  const latitude = numeric(order.drop_off_lat);
  const longitude = numeric(order.drop_off_lng);
  if (latitude && longitude) details.push(`${label("Mapa", "Map")}: https://www.google.com/maps?q=${latitude},${longitude}`);
  if (clean(order.tracking_link)) details.push(`${label("Rastreo", "Tracking")}: ${clean(order.tracking_link)}`);
  if (clean(order.pickup_ready_dt)) details.push(`${label("Hora estimada", "Estimated time")}: ${dateTime(order.pickup_ready_dt)}`);
  section(label("Detalles adicionales", "Additional details"), details);
  add("-".repeat(columns)); center("mediasis");
  bytes.push(0x0a, 0x0a, 0x0a);
  if (cutter) bytes.push(0x1d, 0x56, 0x00);
  return Uint8Array.from(bytes);
}

function marketCacheKey(market: JsonRecord): string {
  if (!market.currency_code || !market.locale || !market.timezone) throw new Error("MARKET_SETTINGS_MISSING");
  return [market.currency_code, market.locale, market.timezone, market.updated_at]
    .map((value) => String(value ?? "").replace(/[^a-zA-Z0-9_-]/g, "_")).join("-");
}

function withCutter(bytes: Uint8Array, cutter: boolean): Uint8Array {
  if (!cutter) return bytes;
  const suffix = new Uint8Array([0x1d, 0x56, 0x00]);
  const output = new Uint8Array(bytes.length + suffix.length);
  output.set(bytes);
  output.set(suffix, bytes.length);
  return output;
}

async function cachedVisualReceiptBytes(
  client: MediasisSupabaseClient,
  orderId: string,
  paper: string,
  cutter: boolean,
  market: JsonRecord,
): Promise<Uint8Array> {
  const cachePath = `${orderId}/${RENDER_VERSION}/${marketCacheKey(market)}/${paper}.escpos`;
  const { data: cached } = await client.storage
    .from(RENDER_CACHE_BUCKET)
    .download(cachePath);
  if (!cached) throw new Error("Cached visual receipt unavailable");
  return withCutter(new Uint8Array(await cached.arrayBuffer()), cutter);
}

Deno.serve(async (request) => {
  try {
    if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });
    const body = await request.json() as JsonRecord;
    const token = await authorize(clean(body.print_authorization));
    const orderId = clean(token.order_id);
    const locationId = clean(token.business_location_id);
    if (!orderId || !locationId) throw new Error("Invalid authorization");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ??
      Deno.env.get("SUPABASE_SECRET_KEY")?.trim() ?? env("SUPABASE_SERVICE_ROLE_KEY");
    const client = createClient(env("SUPABASE_URL"), serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false }, db: { schema: "mediasis" },
    });
    const { data, error } = await client.rpc("get_receipt_print_data_for_background", {
      p_order_id: orderId, p_business_location_id: locationId,
    });
    if (error) throw error;
    const payload = data as { success?: boolean; data?: JsonRecord; message?: string };
    if (!payload?.success || !payload.data) throw new Error(payload?.message ?? "Receipt unavailable");
    const paper = clean(body.paper_width) === "mm58" ? "mm58" : "mm80";
    const cutter = body.supports_cutter === true;
    let bytes: Uint8Array;
    let format = "escPosText";
    if (clean(body.receipt_format) === "visualRaster") {
      try {
        bytes = await withDeadline(
          cachedVisualReceiptBytes(
            client,
            orderId,
            paper,
            cutter,
            object(payload.data.market),
          ),
          7_000,
        );
        if (!bytes.length) throw new Error("Visual receipt is empty");
        format = "visualRaster";
      } catch (error) {
        console.warn("[background-print-receipt] visual fallback", error);
        bytes = receiptBytes(payload.data, paper, cutter);
        format = "escPosTextFallback";
      }
    } else {
      bytes = receiptBytes(payload.data, paper, cutter);
    }
    return new Response(bytes.buffer as ArrayBuffer, {
      headers: {
        "Content-Type": "application/vnd.mediasis.escpos",
        "x-mediasis-receipt-format": format,
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false, message: error instanceof Error ? error.message : "Print failed",
    }), { status: 401, headers: { "Content-Type": "application/json" } });
  }
});
