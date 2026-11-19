import { Router } from "express";
import { query } from "../db.js";
import {
  HttpError,
  uuid,
  iso,
  requireString,
  optionalString,
  optionalDate,
  rateLimit,
} from "../util.js";
import { authRequired } from "../auth.js";

const router = Router();
router.use(authRequired);

const PLATFORMS = ["instagram", "twitter", "facebook", "linkedin"];
const POST_STATUSES = ["draft", "scheduled", "published", "failed"];

function postRow(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    caption: row.caption,
    image_url: row.image_url,
    hashtags: row.hashtags ?? [],
    platform: row.platform,
    scheduled_for: row.scheduled_for,
    status: row.status,
    created_at: row.created_at,
  };
}

async function getPost(id, userId) {
  const { rows } = await query(
    "SELECT * FROM posts WHERE id=$1 AND user_id=$2",
    [id, userId]
  );
  return rows[0] ?? null;
}

router.get("/", async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 100, 200);
    const offset = Math.max(Number(req.query.offset) || 0, 0);
    const { rows } = await query(
      `SELECT * FROM posts WHERE user_id=$1
       ORDER BY created_at DESC LIMIT ${limit} OFFSET ${offset}`,
      [req.userId]
    );
    res.json(rows.map(postRow));
  } catch (err) {
    next(err);
  }
});

const createLimit = rateLimit({ windowMs: 60_000, max: 30 });

router.post("/", createLimit, async (req, res, next) => {
  try {
    const caption = requireString(req.body, "caption", { max: 5000 });
    const imageUrl = optionalString(req.body, "image_url", { max: 2000 });
    const platform = req.body?.platform ?? "instagram";
    if (!PLATFORMS.includes(platform)) {
      throw new HttpError(
        400,
        `Field 'platform' must be one of: ${PLATFORMS.join(", ")}`
      );
    }
    const hashtags = Array.isArray(req.body?.hashtags)
      ? req.body.hashtags
          .filter((t) => typeof t === "string")
          .map((t) => t.trim())
          .filter(Boolean)
          .slice(0, 30)
      : [];
    const scheduledFor = optionalDate(req.body, "scheduled_for");

    const { rows } = await query(
      `INSERT INTO posts (user_id, caption, image_url, hashtags, platform, scheduled_for, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [
        req.userId,
        caption,
        imageUrl,
        hashtags,
        platform,
        scheduledFor,
        scheduledFor ? "scheduled" : "draft",
      ]
    );

    if (scheduledFor) {
      await query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1,'post_scheduled','Post scheduled',
                 'Your ${platform} post is scheduled for ${iso(scheduledFor)}.')`,
        [req.userId]
      );
    }

    res.status(201).json(postRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

router.patch("/:id", async (req, res, next) => {
  try {
    const postId = uuid(req.params.id);
    const post = await getPost(postId, req.userId);
    if (!post) throw new HttpError(404, "Post not found");

    const caption = req.body?.caption;
    if (caption !== undefined) {
      requireString({ caption }, "caption", { max: 5000 });
    }
    const platform = req.body?.platform;
    if (platform !== undefined && !PLATFORMS.includes(platform)) {
      throw new HttpError(
        400,
        `Field 'platform' must be one of: ${PLATFORMS.join(", ")}`
      );
    }
    const status = req.body?.status;
    if (status !== undefined && !POST_STATUSES.includes(status)) {
      throw new HttpError(
        400,
        `Field 'status' must be one of: ${POST_STATUSES.join(", ")}`
      );
    }

    const { rows } = await query(
      `UPDATE posts SET
         caption = COALESCE($1, caption),
         platform = COALESCE($2, platform),
         status = COALESCE($3, status)
       WHERE id=$4 AND user_id=$5 RETURNING *`,
      [
        typeof caption === "string" ? caption.trim() : null,
        platform ?? null,
        status ?? null,
        postId,
        req.userId,
      ]
    );
    res.json(postRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    const postId = uuid(req.params.id);
    const post = await getPost(postId, req.userId);
    if (!post) throw new HttpError(404, "Post not found");
    await query("DELETE FROM posts WHERE id=$1", [postId]);
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

const scheduleLimit = rateLimit({ windowMs: 60_000, max: 20 });

router.post("/:id/schedule", scheduleLimit, async (req, res, next) => {
  try {
    const postId = uuid(req.params.id);
    const post = await getPost(postId, req.userId);
    if (!post) throw new HttpError(404, "Post not found");

    const scheduledFor = optionalDate(req.body, "scheduled_for");
    if (!scheduledFor) {
      throw new HttpError(400, "Field 'scheduled_for' is required");
    }
    if (scheduledFor.getTime() < Date.now() - 60_000) {
      throw new HttpError(400, "Scheduled time must be in the future");
    }

    const { rows } = await query(
      `UPDATE posts SET scheduled_for=$1, status='scheduled'
       WHERE id=$2 RETURNING *`,
      [scheduledFor, postId]
    );

    await query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1,'post_scheduled','Post scheduled',
               'Your ${rows[0].platform} post is scheduled for ${iso(scheduledFor)}.')`,
      [req.userId]
    );

    res.json(postRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

// Caption generation: the iOS app sends { image_url, topic, brand_voice,
// target_audience }; the web client sends { context, tone, niche }.
router.post("/generate-caption", scheduleLimit, async (req, res, next) => {
  try {
    const { runCompletion } = await import("../aiGateway.js");
    const context =
      optionalString(req.body, "topic", { max: 4000 }) ??
      optionalString(req.body, "context", { max: 4000 }) ?? "";
    const brandVoice = optionalString(req.body, "brand_voice", { max: 200 });
    const targetAudience = optionalString(req.body, "target_audience", { max: 200 });
    const niche = optionalString(req.body, "niche", { max: 200 }) ?? "photography";
    const provider = optionalString(req.body, "provider", { max: 50 }) || "anthropic";
    const model =
      optionalString(req.body, "model", { max: 100 }) ||
      "claude-3-5-haiku-20241022";

    const prompt = `You are a social media caption writer for a ${niche} business.
Write one Instagram caption in a ${brandVoice ?? "engaging"} tone${
      targetAudience ? ` aimed at ${targetAudience}` : ""
    }${context ? ` about: ${context}` : ""}.
Return strict JSON: {"caption": "...", "hashtags": ["tag", ...]} with 5-10 hashtags (no # symbol), no other text.`;

    const result = await runCompletion({
      userId: req.userId,
      provider,
      model,
      prompt,
      temperature: 0.8,
      maxTokens: 600,
      apiKey: optionalString(req.body, "api_key", { max: 500 }),
    });

    // Normalize hashtags: the app sends tags without "#", some clients with.
    let caption = "";
    let hashtags = [];
    try {
      const start = result.response.indexOf("{");
      const end = result.response.lastIndexOf("}");
      const parsed = JSON.parse(result.response.slice(start, end + 1));
      caption = String(parsed.caption ?? "").trim();
      hashtags = Array.isArray(parsed.hashtags)
        ? parsed.hashtags.map((t) => {
            const s = String(t).trim();
            return s.startsWith("#") ? s.slice(1) : s;
          })
        : [];
    } catch {
      caption = result.response.trim();
    }
    if (!caption) throw new HttpError(502, "AI returned an empty caption");

    res.status(200).json({ caption, hashtags });
  } catch (err) {
    next(err);
  }
});

export default router;
