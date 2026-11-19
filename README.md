# FrameFlow

FrameFlow is an iOS app (SwiftUI, iOS 17+) for photographers and videographers.
AI agents automate lead discovery ("Scout") and social content ("Marketing");
every agent action that touches the outside world passes through an
approval flow before it runs.

## Repository layout

```
backend/            Node.js (ESM) + Express + Postgres API — the live backend
FrameFlow/          SwiftUI app source (Models / Views / ViewModels / Services / Utils)
FrameFlow.xcodeproj Xcode project (scheme: FrameFlow)
FrameFlowTests/     Unit tests (run in Xcode)
backend/test/       Backend end-to-end tests
```

The `FrameFlowapp/`, `FrameFlowappTests/` and `FrameFlowappUITests/` folders
are the original Xcode template scaffold and are not part of the app; the
`FrameFlowapp` target can be deleted from the Xcode project.

## Running the backend

Requirements: Node 20+, PostgreSQL.

```bash
# 1. Create the database (schema is created automatically on first start)
createdb frameflow

# 2. Configure (all optional — defaults shown)
export DATABASE_URL="postgres://ubuntu:ubuntu@localhost:5432/frameflow"
export PORT=3000
export JWT_SECRET="change-me"            # required in production
export JWT_REFRESH_SECRET="change-me"    # required in production
# Optional provider fallback keys (users can also supply their own per request):
export ANTHROPIC_API_KEY=sk-...
export OPENAI_API_KEY=sk-...

# 3. Start
cd backend && npm install && npm start
```

The API listens on `http://localhost:3000` and exposes `/api/*`.

## Running the iOS app

1. Open `FrameFlow.xcodeproj` in Xcode.
2. Pick the **FrameFlow** scheme and any iOS 17+ simulator.
3. The app talks to `Config.apiBaseURL` (`FrameFlow/UtilsConfig.swift`).
   By default it uses `http://localhost:3000/api`. To point it at a deployed
   backend, add `API_BASE_URL` to an xcconfig or Info.plist build setting —
   the override is read from the bundle's Info dictionary at launch.
4. Run the backend on your Mac (step above), then Cmd+R.
   The simulator reaches it via `http://localhost:3000`.

## Testing

```bash
# Backend end-to-end (spins up its own server on port 3999)
cd backend && npm test          # 44 checks, needs Postgres

# iOS unit tests (macOS only)
xcodebuild test -project FrameFlow.xcodeproj -scheme FrameFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## API summary

All endpoints are under `/api` and (except `auth/*`) require
`Authorization: Bearer <access_token>`. Dates are ISO-8601 without
fractional seconds.

| Area | Endpoints |
|---|---|
| Auth | `POST /auth/signup`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/me` |
| Agents | `GET /agents`, `GET/PATCH /agents/:type`, `PATCH /agents/:type/toggle`, `POST /agents/:type/trigger`, `GET /agents/:type/tasks`, `GET /agents/briefs/:type` |
| Tasks | `GET /tasks`, `GET /tasks/:id`, `PATCH /tasks/:id/approve`, `DELETE /tasks/:id` |
| Leads | `GET /leads`, `GET/PATCH /leads/:id`, `POST /leads/:id/outreach` |
| Posts | `GET/POST /posts`, `PATCH/DELETE /posts/:id`, `POST /posts/:id/schedule`, `POST /posts/generate-caption` |
| Notifications | `GET /notifications`, `PATCH /notifications/:id/read`, `DELETE /notifications/:id` |
| AI | `POST /ai/generate` |
| Uploads | `POST /uploads/image` (multipart, 10 MB max) |

Errors are always `{ "error": "message" }` with a 4xx/5xx status.
