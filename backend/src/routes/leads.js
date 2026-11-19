import { Router } from "express";
import { query } from "../db.js";
import { HttpError, uuid, optionalString, rateLimit } from "../util.js";
import { authRequired } from "../auth.js";

const router = Router();
router.use(authRequired);

const LEAD_STATUSES = [
  "new",
  "contacted",
  "responded",
  "interested",
  "not_interested",
  "converted",
];

function leadRow(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    company_name: row.company_name,
    contact_email: row.contact_email,
    instagram_handle: row.instagram_handle,
    lead_score: row.lead_score,
    reasoning: row.reasoning,
    source: row.source,
    status: row.status,
    notes: row.notes,
    discovered_at: row.discovered_at,
  };
}

async function getLead(id, userId) {
  const { rows } = await query(
    "SELECT * FROM leads WHERE id=$1 AND user_id=$2",
    [id, userId]
  );
  return rows[0] ?? null;
}

router.get("/", async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 100, 200);
    const offset = Math.max(Number(req.query.offset) || 0, 0);
    const statusFilter = req.query.status;
    if (statusFilter && !LEAD_STATUSES.includes(statusFilter)) {
      throw new HttpError(400, "Unknown lead status filter");
    }
    const { rows } = await query(
      `SELECT * FROM leads WHERE user_id=$1
       ${statusFilter ? "AND status=$2" : ""}
       ORDER BY discovered_at DESC LIMIT ${limit} OFFSET ${offset}`,
      statusFilter ? [req.userId, statusFilter] : [req.userId]
    );
    res.json(rows.map(leadRow));
  } catch (err) {
    next(err);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const lead = await getLead(uuid(req.params.id), req.userId);
    if (!lead) throw new HttpError(404, "Lead not found");
    res.json(leadRow(lead));
  } catch (err) {
    next(err);
  }
});

router.patch("/:id", async (req, res, next) => {
  try {
    const leadId = uuid(req.params.id);
    const lead = await getLead(leadId, req.userId);
    if (!lead) throw new HttpError(404, "Lead not found");

    const status = req.body?.status;
    if (status !== undefined) {
      if (typeof status !== "string" || !LEAD_STATUSES.includes(status)) {
        throw new HttpError(
          400,
          `Field 'status' must be one of: ${LEAD_STATUSES.join(", ")}`
        );
      }
    }
    const notes = req.body?.notes;
    if (notes !== undefined && typeof notes !== "string") {
      throw new HttpError(400, "Field 'notes' must be a string");
    }

    const { rows } = await query(
      `UPDATE leads SET
         status = COALESCE($1, status),
         notes = COALESCE($2, notes)
       WHERE id=$3 AND user_id=$4 RETURNING *`,
      [
        status ?? null,
        typeof notes === "string" ? notes.slice(0, 5000) : null,
        leadId,
        req.userId,
      ]
    );
    res.json(leadRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

const outreachLimit = rateLimit({ windowMs: 60_000, max: 20 });

router.post("/:id/outreach", outreachLimit, async (req, res, next) => {
  try {
    const leadId = uuid(req.params.id);
    const lead = await getLead(leadId, req.userId);
    if (!lead) throw new HttpError(404, "Lead not found");

    const message = optionalString(req.body, "message", { max: 5000 });
    if (!message) {
      throw new HttpError(400, "Field 'message' is required");
    }
    const platform = optionalString(req.body, "platform", { max: 50 }) || "instagram";

    await query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1,'lead_found','Outreach queued',
               'Outreach to ${lead.instagram_handle ?? lead.company_name ?? "lead"} via ${platform} was logged.')`,
      [req.userId]
    );

    const { rows } = await query(
      "UPDATE leads SET status='contacted' WHERE id=$1 RETURNING *",
      [leadId]
    );
    res.status(200).json({
      success: true,
      lead: leadRow(rows[0]),
      outreach: { platform, message, sent_at: new Date().toISOString().replace(/\.\d{3}Z$/, "Z") },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
