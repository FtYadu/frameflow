#!/usr/bin/env node
// End-to-end test: boots the API against Postgres and exercises every route
// the iOS app calls. Run with: npm test
import { spawn } from "node:child_process";
import { setTimeout as wait } from "node:timers/promises";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE = process.env.TEST_BASE_URL || "http://localhost:3999/api";

let passed = 0;
let failed = 0;
const failures = [];

function check(name, cond, detail = "") {
  if (cond) {
    passed++;
    console.log(`  ok   ${name}`);
  } else {
    failed++;
    failures.push(name);
    console.log(`  FAIL ${name} ${detail}`);
  }
}

async function req(method, url, { token, body, form } = {}) {
  const headers = {};
  if (token) headers.authorization = `Bearer ${token}`;
  if (form) {
    // multipart handled via fetch FormData
  } else if (body !== undefined) {
    headers["content-type"] = "application/json";
  }
  const res = await fetch(`${BASE}${url}`, {
    method,
    headers,
    body: form ?? (body !== undefined ? JSON.stringify(body) : undefined),
  });
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch {}
  return { status: res.status, json, text };
}

async function main() {
  // Spawn server on a test port
  const server = spawn("node", ["src/server.js"], {
    cwd: path.join(__dirname, ".."),
    env: {
      ...process.env,
      PORT: "3999",
      DATABASE_URL:
        process.env.DATABASE_URL ||
        "postgres://ubuntu:ubuntu@localhost:5432/frameflow",
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  server.stderr.on("data", (d) => process.stderr.write(d));

  let up = false;
  for (let i = 0; i < 40; i++) {
    try {
      const r = await fetch("http://localhost:3999/health");
      if (r.ok) {
        up = true;
        break;
      }
    } catch {}
    await wait(250);
  }
  check("server boots and /health responds", up);
  if (!up) {
    server.kill();
    process.exit(1);
  }

  const email = `e2e-${Date.now()}@frameflow.test`;

  // ---- Auth ----
  let r = await req("POST", "/auth/signup", {
    body: { email, password: "secret123", full_name: "E2E Tester" },
  });
  check("signup returns 201 with user + tokens", r.status === 201 && r.json?.user?.id && r.json?.access_token, r.text.slice(0, 200));
  const { access_token: token, refresh_token: refresh } = r.json ?? {};
  check("signup returns snake_case user fields", r.json?.user?.full_name === "E2E Tester");

  r = await req("POST", "/auth/signup", {
    body: { email, password: "secret123", full_name: "Dup" },
  });
  check("duplicate signup returns 409", r.status === 409);

  r = await req("POST", "/auth/login", {
    body: { email, password: "wrongpass" },
  });
  check("bad password returns 401", r.status === 401);

  r = await req("POST", "/auth/login", {
    body: { email, password: "secret123" },
  });
  check("login returns tokens", r.status === 200 && r.json?.access_token);

  r = await req("POST", "/auth/refresh", { body: { refresh_token: refresh } });
  check("refresh returns new tokens", r.status === 200 && r.json?.access_token);

  r = await req("POST", "/auth/refresh", { body: { refresh_token: "garbage" } });
  check("bad refresh token returns 401", r.status === 401);

  r = await req("GET", "/auth/me", { token });
  check("GET /auth/me with token", r.status === 200 && r.json?.email === email);

  r = await req("GET", "/auth/me");
  check("GET /auth/me without token returns 401", r.status === 401);

  // ---- Agents ----
  r = await req("GET", "/agents", { token });
  check("agents list has scout + marketing defaults",
    r.status === 200 &&
    Array.isArray(r.json) &&
    ["scout", "marketing"].every((t) => r.json.some((a) => a.agent_type === t)),
    JSON.stringify(r.json)?.slice(0, 200));

  r = await req("GET", "/agents/scout", { token });
  check("GET single agent by type", r.status === 200 && r.json?.agent_type === "scout");

  r = await req("PATCH", "/agents/scout/toggle", { token, body: { is_active: false } });
  check("toggle agent off", r.status === 200 && r.json?.is_active === false);

  r = await req("POST", "/agents/scout/trigger", { token, body: { action: "run" } });
  check("triggering paused agent returns 400", r.status === 400);

  await req("PATCH", "/agents/scout/toggle", { token, body: { is_active: true } });

  r = await req("POST", "/agents/scout/trigger", {
    token,
    body: { action: "run", parameters: { targets: ["@studio_a", "@studio_b"] } },
  });
  check("scout trigger creates tasks", r.status === 200 && r.json?.tasks?.length === 2, r.text.slice(0, 200));
  const firstTaskId = r.json?.tasks?.[0]?.id;

  r = await req("GET", "/agents/scout/tasks", { token });
  check("agent tasks listed", r.status === 200 && r.json?.length >= 2);

  r = await req("GET", "/agents/briefs/scout", { token });
  check("briefs endpoint (null before run)", r.status === 200);

  // ---- Tasks ----
  r = await req("GET", "/tasks", { token });
  check("tasks list", r.status === 200 && r.json?.length >= 2);

  r = await req("GET", `/tasks/${firstTaskId}`, { token });
  check("single task fetch", r.status === 200 && r.json?.id === firstTaskId);

  r = await req("PATCH", `/tasks/${firstTaskId}/approve`, { token, body: { approved: true } });
  check("approve task", r.status === 200 && r.json?.status === "approved");

  r = await req("PATCH", `/tasks/${firstTaskId}/approve`, { token, body: { approved: true } });
  check("re-approving returns 400", r.status === 400);

  const otherTaskId = (await req("GET", "/tasks", { token })).json.find((t) => t.id !== firstTaskId)?.id;
  r = await req("PATCH", `/tasks/${otherTaskId}/approve`, { token, body: { approved: false, feedback: "not relevant" } });
  check("reject task with feedback", r.status === 200 && r.json?.status === "rejected");

  // ---- Leads ----
  r = await req("GET", "/leads", { token });
  check("scout created leads", r.status === 200 && r.json?.length >= 2, r.text.slice(0, 200));
  const leadId = r.json?.[0]?.id;
  check("lead fields serialized", r.json?.[0]?.lead_score >= 0 && r.json?.[0]?.discovered_at?.endsWith("Z"), JSON.stringify(r.json?.[0]));

  r = await req("PATCH", `/leads/${leadId}`, { token, body: { status: "contacted", notes: "emailed" } });
  check("update lead status", r.status === 200 && r.json?.status === "contacted");

  r = await req("PATCH", `/leads/${leadId}`, { token, body: { status: "bogus" } });
  check("invalid lead status returns 400", r.status === 400);

  r = await req("POST", `/leads/${leadId}/outreach`, { token, body: { message: "Hi, love your work!", platform: "instagram" } });
  check("lead outreach", r.status === 200 && r.json?.success === true && r.json?.lead?.status === "contacted");

  r = await req("GET", `/leads/${leadId}`);
  check("leads require auth", r.status === 401);

  // ---- Posts ----
  r = await req("POST", "/posts", {
    token,
    body: {
      caption: "Golden hour session",
      hashtags: ["#sunset", "#photography"],
      platform: "instagram",
    },
  });
  check("create draft post", r.status === 201 && r.json?.status === "draft" && Array.isArray(r.json?.hashtags), r.text.slice(0, 200));
  const postId = r.json?.id;

  r = await req("POST", `/posts/${postId}/schedule`, {
    token,
    body: { scheduled_for: new Date(Date.now() + 3600_000).toISOString() },
  });
  check("schedule post", r.status === 200 && r.json?.status === "scheduled");

  r = await req("POST", `/posts/${postId}/schedule`, {
    token,
    body: { scheduled_for: "2020-01-01T00:00:00Z" },
  });
  check("scheduling in the past returns 400", r.status === 400);

  r = await req("PATCH", `/posts/${postId}`, { token, body: { caption: "Updated caption" } });
  check("update post", r.status === 200 && r.json?.caption === "Updated caption");

  r = await req("GET", "/posts", { token });
  check("posts list", r.status === 200 && r.json?.length >= 1);

  // ---- Notifications ----
  r = await req("GET", "/notifications", { token });
  check("notifications exist from earlier actions", r.status === 200 && r.json?.length >= 3, r.text.slice(0, 300));
  const notifId = r.json?.[0]?.id;
  check("notification has Z-suffixed date", r.json?.[0]?.created_at?.endsWith("Z"));

  r = await req("PATCH", `/notifications/${notifId}/read`, { token, body: { is_read: true } });
  check("mark notification read", r.status === 200 && r.json?.is_read === true);

  // ---- AI (no provider key set -> graceful 403) ----
  r = await req("POST", "/ai/generate", { token, body: { prompt: "say hi" } });
  check("ai/generate without key returns 403", r.status === 403, r.text.slice(0, 200));

  r = await req("POST", "/posts/generate-caption", { token, body: { context: "beach shoot" } });
  check("caption generation without key returns 403", r.status === 403);

  // ---- Uploads ----
  const form = new FormData();
  const png = Buffer.from(
    "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d4944415478da63fcffff3f00050001f9342fee0000000049454e44ae426082",
    "hex"
  );
  form.append("image", new Blob([png], { type: "image/png" }), "test.png");
  r = await fetch(`${BASE}/uploads/image`, {
    method: "POST",
    headers: { authorization: `Bearer ${token}` },
    body: form,
  }).then(async (res) => ({ status: res.status, json: await res.json() }));
  check("image upload returns URL", r.status === 201 && r.json?.url?.includes("/uploads/"), JSON.stringify(r.json));

  if (r.json?.url) {
    const img = await fetch(r.json.url);
    check("uploaded image is served", img.ok && img.headers.get("content-type") === "image/png");
  }

  // ---- User isolation ----
  const r2 = await req("POST", "/auth/signup", {
    body: { email: `other-${email}`, password: "secret123", full_name: "Other" },
  });
  const token2 = r2.json?.access_token;
  r = await req("GET", `/tasks/${firstTaskId}`, { token: token2 });
  check("other user cannot read tasks", r.status === 404);
  r = await req("GET", "/leads", { token: token2 });
  check("other user sees zero leads", r.status === 200 && r.json?.length === 0);

  // ---- Logout ----
  r = await req("POST", "/auth/logout", { body: { refresh_token: refresh } });
  check("logout succeeds", r.status === 200);
  r = await req("POST", "/auth/refresh", { body: { refresh_token: refresh } });
  check("refresh revoked after logout", r.status === 401);

  server.kill();
  await wait(200);

  console.log(`\n${passed} passed, ${failed} failed`);
  if (failures.length) {
    console.log("Failures:", failures.join(", "));
    process.exit(1);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
