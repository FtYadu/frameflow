import express from "express";
import path from "node:path";
import multer from "multer";
import { fileURLToPath } from "node:url";
import { initSchema, pool } from "./db.js";
import { HttpError } from "./util.js";
import authRoutes from "./routes/auth.js";
import agentRoutes from "./routes/agents.js";
import taskRoutes from "./routes/tasks.js";
import leadRoutes from "./routes/leads.js";
import postRoutes from "./routes/posts.js";
import notificationRoutes from "./routes/notifications.js";
import aiRoutes from "./routes/ai.js";
import uploadRoutes, { uploadDir } from "./routes/uploads.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
app.disable("x-powered-by");
app.set("trust proxy", 1);
app.use(express.json({ limit: "2mb" }));

// Health check (no auth) — used by load balancers and CI.
app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok" });
  } catch {
    res.status(503).json({ status: "degraded", db: "unreachable" });
  }
});

app.use("/uploads", express.static(uploadDir, { maxAge: "7d" }));

const api = express.Router();
api.use("/auth", authRoutes);
api.use("/agents", agentRoutes);
api.use("/tasks", taskRoutes);
api.use("/leads", leadRoutes);
api.use("/posts", postRoutes);
api.use("/notifications", notificationRoutes);
api.use("/ai", aiRoutes);
api.use("/uploads", uploadRoutes);
app.use("/api", api);

app.use((req, res) => {
  res.status(404).json({ error: `No route for ${req.method} ${req.path}` });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({ error: err.message });
  }
  const status = err.status ?? 500;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: err.message || "Internal server error" });
});

const PORT = Number(process.env.PORT) || 3000;

initSchema()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`FrameFlow API listening on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error("Failed to start: database schema error", err);
    process.exit(1);
  });

export default app;
