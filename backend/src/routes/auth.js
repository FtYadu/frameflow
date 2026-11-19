import { Router } from "express";
import crypto from "node:crypto";
import bcrypt from "bcryptjs";
import { query } from "../db.js";
import {
  HttpError,
  requireString,
  optionalString,
  rateLimit,
} from "../util.js";
import {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  authRequired,
} from "../auth.js";

const router = Router();
const strictLimit = rateLimit({ windowMs: 60_000, max: 20 });

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function userRow(row) {
  return {
    id: row.id,
    email: row.email,
    full_name: row.full_name,
    instagram_handle: row.instagram_handle,
    niche: row.niche,
    subscription_tier: row.subscription_tier ?? "free",
    created_at: row.created_at,
  };
}

async function issueTokens(userId) {
  const access = signAccessToken(userId);
  const refresh = signRefreshToken(userId);
  const hash = crypto.createHash("sha256").update(refresh).digest("hex");
  await query(
    `INSERT INTO refresh_tokens (token_hash, user_id, expires_at)
     VALUES ($1,$2, now() + interval '30 days')
     ON CONFLICT (token_hash) DO UPDATE SET user_id = EXCLUDED.user_id, expires_at = EXCLUDED.expires_at`,
    [hash, userId]
  );
  return { access_token: access, refresh_token: refresh };
}

function authResponse(user, tokens) {
  return { user: userRow(user), ...tokens };
}

async function createDefaultAgents(userId) {
  await query(
    `INSERT INTO agents (user_id, agent_type) VALUES ($1,'scout'), ($1,'marketing')
     ON CONFLICT (user_id, agent_type) DO NOTHING`,
    [userId]
  );
}

router.post(
  "/signup",
  strictLimit,
  async (req, res, next) => {
    try {
      const email = requireString(req.body, "email", { max: 320 }).toLowerCase();
      const password = requireString(req.body, "password", { max: 200 });
      const fullName = requireString(req.body, "full_name", { max: 200 });
      const instagramHandle = optionalString(req.body, "instagram_handle", {
        max: 100,
      });
      const niche = optionalString(req.body, "niche", { max: 200 });

      if (!EMAIL_RE.test(email)) {
        throw new HttpError(400, "Please enter a valid email address");
      }
      if (password.length < 6) {
        throw new HttpError(400, "Password must be at least 6 characters");
      }

      const existing = await query("SELECT id FROM users WHERE email=$1", [
        email,
      ]);
      if (existing.rows.length > 0) {
        throw new HttpError(409, "An account with this email already exists");
      }

      const passwordHash = await bcrypt.hash(password, 10);
      const { rows } = await query(
        `INSERT INTO users (email, password_hash, full_name, instagram_handle, niche)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [email, passwordHash, fullName, instagramHandle, niche]
      );
      const user = rows[0];

      await createDefaultAgents(user.id);
      await query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1,'system','Welcome to FrameFlow','Your agents are ready to run.')`,
        [user.id]
      );

      const tokens = await issueTokens(user.id);
      res.status(201).json(authResponse(user, tokens));
    } catch (err) {
      next(err);
    }
  }
);

router.post(
  "/login",
  strictLimit,
  async (req, res, next) => {
    try {
      const email = requireString(req.body, "email", { max: 320 }).toLowerCase();
      const password = requireString(req.body, "password", { max: 200 });

      const { rows } = await query("SELECT * FROM users WHERE email=$1", [
        email,
      ]);
      const user = rows[0];
      const ok =
        user && (await bcrypt.compare(password, user.password_hash));
      if (!ok) throw new HttpError(401, "Invalid email or password");

      await createDefaultAgents(user.id);
      const tokens = await issueTokens(user.id);
      res.json(authResponse(user, tokens));
    } catch (err) {
      next(err);
    }
  }
);

router.post("/refresh", strictLimit, async (req, res, next) => {
  try {
    const refreshToken = requireString(req.body, "refresh_token", {
      max: 2000,
    });
    const payload = verifyRefreshToken(refreshToken);

    const hash = crypto.createHash("sha256").update(refreshToken).digest("hex");
    const stored = await query(
      "SELECT 1 FROM refresh_tokens WHERE token_hash=$1 AND expires_at > now()",
      [hash]
    );
    if (stored.rows.length === 0) {
      throw new HttpError(401, "Refresh token has been revoked");
    }

    const { rows } = await query("SELECT * FROM users WHERE id=$1", [
      payload.sub,
    ]);
    if (rows.length === 0) throw new HttpError(401, "User no longer exists");

    const tokens = await issueTokens(payload.sub);
    res.json(authResponse(rows[0], tokens));
  } catch (err) {
    next(err);
  }
});

router.post("/logout", strictLimit, async (req, res, next) => {
  try {
    const refreshToken = req.body?.refresh_token;
    if (typeof refreshToken === "string" && refreshToken.length > 0) {
      const hash = crypto.createHash("sha256").update(refreshToken).digest("hex");
      await query("DELETE FROM refresh_tokens WHERE token_hash=$1", [hash]);
    }
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

router.get("/me", authRequired, async (req, res, next) => {
  try {
    const { rows } = await query("SELECT * FROM users WHERE id=$1", [
      req.userId,
    ]);
    if (rows.length === 0) throw new HttpError(401, "User not found");
    res.json(userRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

export default router;
