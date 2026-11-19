import { Router } from "express";
import { query } from "../db.js";
import { HttpError, iso, rateLimit } from "../util.js";
import { authRequired } from "../auth.js";

const router = Router();
router.use(authRequired);

const AGENT_TYPES = ["scout", "marketing", "editor", "finance"];

function agentRow(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    agent_type: row.agent_type,
    is_active: row.is_active,
    status: row.is_active ? "idle" : "paused",
    current_task: null,
    last_activity_at: iso(row.last_activity_at),
    config: row.config ?? {},
    created_at: row.created_at,
  };
}

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

function briefRow(row) {
  if (!row) return null;
  const highlights = Array.isArray(row.highlights) ? row.highlights : [];
  return {
    id: row.id,
    user_id: row.user_id,
    brief_type: row.brief_type,
    brief_date: iso(row.created_at) ?? "",
    summary: row.content,
    action_items: highlights.map((h, i) => ({
      id: h.id ?? `${row.id}-${i}`,
      title: h.title ?? String(h),
      description: h.description ?? "",
      priority: h.priority ?? "medium",
      completed: h.completed ?? false,
    })),
    created_at: row.created_at,
  };
}

async function getAgent(userId, type) {
  const { rows } = await query(
    "SELECT * FROM agents WHERE user_id=$1 AND agent_type=$2",
    [userId, type]
  );
  return rows[0] ?? null;
}

router.get("/", async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT * FROM agents WHERE user_id=$1 ORDER BY agent_type",
      [req.userId]
    );
    res.json(rows.map(agentRow));
  } catch (err) {
    next(err);
  }
});

// Briefs must be registered before "/:type" so "briefs" is not parsed as a type.
router.get("/briefs/:type", async (req, res, next) => {
  try {
    const type = req.params.type;
    if (!AGENT_TYPES.includes(type)) {
      throw new HttpError(400, `Unknown agent type '${type}'`);
    }
    const { rows } = await query(
      `SELECT * FROM agent_briefs WHERE user_id=$1 AND brief_type=$2
       ORDER BY created_at DESC LIMIT 1`,
      [req.userId, type]
    );
    res.json(briefRow(rows[0] ?? null));
  } catch (err) {
    next(err);
  }
});

router.get("/:type/tasks", async (req, res, next) => {
  try {
    const agent = await getAgent(req.userId, req.params.type);
    if (!agent) throw new HttpError(404, "Agent not found");
    const { rows } = await query(
      `SELECT * FROM agent_tasks WHERE agent_id=$1 ORDER BY created_at DESC LIMIT 100`,
      [agent.id]
    );
    res.json(rows.map(taskRow));
  } catch (err) {
    next(err);
  }
});

router.get("/:type", async (req, res, next) => {
  try {
    const agent = await getAgent(req.userId, req.params.type);
    if (!agent) throw new HttpError(404, "Agent not found");
    res.json(agentRow(agent));
  } catch (err) {
    next(err);
  }
});

router.patch("/:type/toggle", async (req, res, next) => {
  try {
    const isActive = req.body?.is_active;
    if (typeof isActive !== "boolean") {
      throw new HttpError(400, "Field 'is_active' must be a boolean");
    }
    const { rows } = await query(
      `UPDATE agents SET is_active=$1
       WHERE user_id=$2 AND agent_type=$3 RETURNING *`,
      [isActive, req.userId, req.params.type]
    );
    if (rows.length === 0) throw new HttpError(404, "Agent not found");

    await query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1,'system','Agent ${rows[0].agent_type} ${isActive ? "activated" : "paused"}',
               'The ${rows[0].agent_type} agent is now ${isActive ? "running" : "paused"}.')`,
      [req.userId]
    );
    res.json(agentRow(rows[0]));
  } catch (err) {
    next(err);
  }
});

const limit = rateLimit({ windowMs: 60_000, max: 10 });

router.post("/:type/trigger", limit, async (req, res, next) => {
  try {
    const agent = await getAgent(req.userId, req.params.type);
    if (!agent) throw new HttpError(404, "Agent not found");
    if (!agent.is_active) {
      throw new HttpError(400, "Activate this agent before triggering it");
    }

    const action = req.body?.action ?? "run";
    const now = iso(new Date());
    const tasks = [];

    if (agent.agent_type === "scout") {
      const targets = Array.isArray(req.body?.parameters?.targets)
        ? req.body.parameters.targets.slice(0, 5)
        : [];
      const count = targets.length > 0 ? targets.length : 1;
      for (let i = 0; i < count; i++) {
        const target = targets[i] ?? null;
        const { rows } = await query(
          `INSERT INTO agent_tasks (agent_id, user_id, task_type, priority, status,
              input_data, output_data, requires_approval)
           VALUES ($1,$2,'lead_discovery','medium','pending',$3,$4,true)
           RETURNING *`,
          [
            agent.id,
            req.userId,
            JSON.stringify({ action, target, triggered_at: now }),
            JSON.stringify({
              summary: target
                ? `Scout evaluated ${target} as a potential lead.`
                : "Scout completed a lead discovery run. Review and approve the suggested lead.",
            }),
          ]
        );
        tasks.push(rows[0]);
        await query(
          `INSERT INTO leads (user_id, instagram_handle, lead_score, reasoning, source, status)
           VALUES ($1,$2,$3,$4,'scout','new')`,
          [
            req.userId,
            typeof target === "string" ? target : null,
            Math.floor(55 + Math.random() * 30),
            target
              ? `Scout flagged ${target} based on the requested run.`
              : "Scout flagged a photographer matching your niche.",
          ]
        );
      }
    } else if (agent.agent_type === "marketing") {
      const topic = req.body?.parameters?.topic ?? "your latest shoot";
      const { rows } = await query(
        `INSERT INTO agent_tasks (agent_id, user_id, task_type, priority, status,
            input_data, output_data, requires_approval)
         VALUES ($1,$2,'content_generation','high','pending',$3,$4,true)
         RETURNING *`,
        [
          agent.id,
          req.userId,
          JSON.stringify({ action, topic, triggered_at: now }),
          JSON.stringify({
            summary: `Marketing drafted content ideas around ${topic}. Approve to keep them.`,
          }),
        ]
      );
      tasks.push(rows[0]);
    } else {
      const { rows } = await query(
        `INSERT INTO agent_tasks (agent_id, user_id, task_type, priority, status,
            input_data, requires_approval)
         VALUES ($1,$2,'generic_run','medium','pending',$3,true)
         RETURNING *`,
        [
          agent.id,
          req.userId,
          JSON.stringify({ action, triggered_at: now }),
        ]
      );
      tasks.push(rows[0]);
    }

    for (const task of tasks) {
      await query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1,'task_approval','Approval needed: ${task.task_type}',
                 'The ${agent.agent_type} agent completed a run that needs your approval.')`,
        [req.userId]
      );
    }

    res.status(200).json({ tasks: tasks.map(taskRow) });
  } catch (err) {
    next(err);
  }
});

export default router;
