import { Router } from "express";
import { query } from "../db.js";
import { HttpError, uuid, optionalString } from "../util.js";
import { authRequired } from "../auth.js";

const router = Router();
router.use(authRequired);

function taskRow(row) {
  return {
    id: row.id,
    agent_id: row.agent_id,
    user_id: row.user_id,
    task_type: row.task_type,
    priority: row.priority,
    status: row.status,
    input_data: row.input_data ?? {},
    output_data: row.output_data,
    requires_approval: row.requires_approval,
    approved_by_user: row.approved_by_user,
    created_at: row.created_at,
  };
}

async function getUserTask(taskId, userId) {
  const { rows } = await query(
    "SELECT * FROM agent_tasks WHERE id=$1 AND user_id=$2",
    [taskId, userId]
  );
  return rows[0] ?? null;
}

router.get("/", async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT * FROM agent_tasks WHERE user_id=$1 ORDER BY created_at DESC LIMIT 200`,
      [req.userId]
    );
    res.json(rows.map(taskRow));
  } catch (err) {
    next(err);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const task = await getUserTask(uuid(req.params.id), req.userId);
    if (!task) throw new HttpError(404, "Task not found");
    res.json(taskRow(task));
  } catch (err) {
    next(err);
  }
});

router.patch("/:id/approve", async (req, res, next) => {
  try {
    const taskId = uuid(req.params.id);
    const task = await getUserTask(taskId, req.userId);
    if (!task) throw new HttpError(404, "Task not found");
    if (task.status !== "pending") {
      throw new HttpError(400, `Task is already ${task.status}`);
    }

    const approved = req.body?.approved !== false; // default approve
    const feedback = optionalString(req.body, "feedback", { max: 2000 });

    const status = approved ? "approved" : "rejected";
    const { rows } = await query(
      `UPDATE agent_tasks
       SET status=$1, approved_by_user=$2,
           output_data = output_data || $3::jsonb
       WHERE id=$4 RETURNING *`,
      [
        status,
        approved,
        JSON.stringify(feedback ? { user_feedback: feedback } : {}),
        taskId,
      ]
    );

    await query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1,'system','Task ${status}',
               'Your ${rows[0].task_type} task was ${status}.')`,
      [req.userId]
    );

    res.json(taskRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    const taskId = uuid(req.params.id);
    const task = await getUserTask(taskId, req.userId);
    if (!task) throw new HttpError(404, "Task not found");
    await query("DELETE FROM agent_tasks WHERE id=$1", [taskId]);
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
