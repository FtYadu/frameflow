import { Router } from "express";
import { query } from "../db.js";
import { HttpError, uuid } from "../util.js";
import { authRequired } from "../auth.js";

const router = Router();
router.use(authRequired);

function notificationRow(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    type: row.type,
    title: row.title,
    message: row.message,
    is_read: row.is_read,
    created_at: row.created_at,
  };
}

router.get("/", async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 100, 200);
    const offset = Math.max(Number(req.query.offset) || 0, 0);
    const { rows } = await query(
      `SELECT * FROM notifications WHERE user_id=$1
       ORDER BY created_at DESC LIMIT ${limit} OFFSET ${offset}`,
      [req.userId]
    );
    res.json(rows.map(notificationRow));
  } catch (err) {
    next(err);
  }
});

router.patch("/:id/read", async (req, res, next) => {
  try {
    const notificationId = uuid(req.params.id);
    const isRead = req.body?.is_read !== false;
    const { rows } = await query(
      `UPDATE notifications SET is_read=$1
       WHERE id=$2 AND user_id=$3 RETURNING *`,
      [isRead, notificationId, req.userId]
    );
    if (rows.length === 0) throw new HttpError(404, "Notification not found");
    res.json(notificationRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    const notificationId = uuid(req.params.id);
    const { rows } = await query(
      "DELETE FROM notifications WHERE id=$1 AND user_id=$2 RETURNING id",
      [notificationId, req.userId]
    );
    if (rows.length === 0) throw new HttpError(404, "Notification not found");
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
