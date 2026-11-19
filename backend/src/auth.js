import jwt from "jsonwebtoken";
import { HttpError } from "./util.js";

export const JWT_SECRET =
  process.env.JWT_SECRET || "dev-only-secret-change-me";
export const JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || "dev-only-refresh-secret-change-me";

const ACCESS_TTL = process.env.JWT_ACCESS_TTL || "15m";
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

export function signAccessToken(userId) {
  return jwt.sign({ sub: userId, type: "access" }, JWT_SECRET, {
    expiresIn: ACCESS_TTL,
  });
}

export function signRefreshToken(userId) {
  return jwt.sign({ sub: userId, type: "refresh" }, JWT_REFRESH_SECRET, {
    expiresIn: "30d",
  });
}

export function verifyAccessToken(token) {
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload.type !== "access") throw new Error();
    return payload;
  } catch {
    throw new HttpError(401, "Invalid or expired access token");
  }
}

export function verifyRefreshToken(token) {
  try {
    const payload = jwt.verify(token, JWT_REFRESH_SECRET);
    if (payload.type !== "refresh") throw new Error();
    return payload;
  } catch {
    throw new HttpError(401, "Invalid or expired refresh token");
  }
}

export function authRequired(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return next(new HttpError(401, "Missing bearer token"));
  }
  try {
    const payload = verifyAccessToken(token);
    req.userId = payload.sub;
    next();
  } catch (err) {
    next(err);
  }
}
