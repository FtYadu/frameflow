import crypto from "node:crypto";

// Swift's JSONDecoder .iso8601 strategy rejects fractional seconds,
// so all dates are serialized as "2026-11-19T12:00:00Z".
export function iso(value) {
  if (!value) return null;
  const d = value instanceof Date ? value : new Date(value);
  return d.toISOString().replace(/\.\d{3}Z$/, "Z");
}

export function uuid(v) {
  if (!v) return crypto.randomUUID();
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v)
  ) {
    const err = new Error("Invalid id format");
    err.status = 400;
    throw err;
  }
  return v;
}

export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function requireString(body, field, { max = 10_000 } = {}) {
  const v = body?.[field];
  if (typeof v !== "string" || v.trim() === "") {
    throw new HttpError(400, `Field '${field}' is required`);
  }
  if (v.length > max) {
    throw new HttpError(400, `Field '${field}' exceeds ${max} characters`);
  }
  return v.trim();
}

export function optionalString(body, field, { max = 10_000 } = {}) {
  const v = body?.[field];
  if (v === undefined || v === null) return null;
  if (typeof v !== "string") {
    throw new HttpError(400, `Field '${field}' must be a string`);
  }
  if (v.length > max) {
    throw new HttpError(400, `Field '${field}' exceeds ${max} characters`);
  }
  return v.trim();
}

export function optionalDate(body, field) {
  const v = body?.[field];
  if (v === undefined || v === null || v === "") return null;
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) {
    throw new HttpError(400, `Field '${field}' is not a valid date`);
  }
  return d;
}

// Simple in-memory fixed-window rate limiter (per IP + route bucket).
export function rateLimit({ windowMs = 60_000, max = 120 } = {}) {
  const buckets = new Map();
  setInterval(() => {
    const cutoff = Date.now() - windowMs;
    for (const [key, entry] of buckets) {
      if (entry.reset < cutoff) buckets.delete(key);
    }
  }, windowMs).unref();

  return (req, res, next) => {
    const key = `${req.ip}:${req.baseUrl}${req.route?.path ?? ""}`;
    const now = Date.now();
    let entry = buckets.get(key);
    if (!entry || entry.reset < now) {
      entry = { count: 0, reset: now + windowMs };
      buckets.set(key, entry);
    }
    entry.count += 1;
    if (entry.count > max) {
      return res
        .status(429)
        .json({ error: "Too many requests, try again later" });
    }
    next();
  };
}
