# FaceAlert + Specter deployment

Updated 2026-09-25. This describes the current server architecture and deployment wiring,
not a completed production acceptance test. The client integration is implemented and
locally tested; real-camera and deployed acceptance remain pending. See the
[current integration status](../../../../integration_plan_fa_specter.md).

## Topology and data ownership

- Specter is the source of truth for cameras, watchlists, targets, reference photos,
  enrollment and alerts. Camera app fields such as creator and location live in
  `metadata.fa`; camera IDs are Specter IDs, not a second `specter_camera_id` mapping.
- Supabase stores users and camera assignments. There is one configured
  `SPECTER_OWNER_ID` per fa-server deployment, not an organization-to-owner resolver.
- The typed anti-corruption layer is in [server/src/specter](../../server/src/specter).
  Browsers use fa's authenticated `/api` routes, never Specter's service token.
- NATS ordered ephemeral consumers relay live events into authenticated Socket.IO
  rooms. Alerts are read and changed through Specter's HTTP API; no MongoDB alert copy
  or durable fa alert-ingestion backlog is maintained. After downtime, refetch HTTP
  state. Camera status consumers start with the last status per subject.
- MongoDB and MinIO remain in fa's Compose stack for existing/legacy functionality;
  their presence does not make them authoritative for Specter resources.

## Compose wiring

Use Specter's [base Compose file](../../../../deploy/compose.base.yaml) together with
its [application Compose file](../../../../deploy/compose.yaml). The project name is
`specter`, so its default network is `specter_default`. Its service DNS names are
`api`, `nats`, `qdrant`, `go2rtc`, `migrate`, `camera-manager` and `detector`.
Starting only the base file does not start the Specter API or vision processes.

The [fa-server Compose file](../../server/docker-compose.yml) attaches only fa-server
to the external `${SPECTER_NETWORK:-specter_default}` network. It also explicitly
retains its own `default` network, where `mongo` and `minio` remain reachable.
Use separate Compose projects; do not merge the fa file into Specter's project.

| Setting | Container value / operator requirement |
| --- | --- |
| `SPECTER_API_URL` | `http://api:8000` (not container localhost or `specter-api`) |
| `SPECTER_NATS_URL` | `nats://nats:4222` (not `NATS_URL`) |
| `QDRANT_URL` | `http://qdrant:6333` for fa's existing vector diagnostics |
| `SPECTER_OWNER_ID` | Defaults to `facealert`; only lowercase letters, digits and underscores |
| `SPECTER_NETWORK` | Compose network name; override if Specter uses a different project name |
| `SPECTER_API_TOKEN_FILE` | `/run/secrets/specter_api_token` |
| `NODE_ENV` | Defaults to `production` |
| `PORT`, `HOST` | `12113`, `0.0.0.0` inside fa-server |

The file secret source is [deploy/secrets/api.token](../../../../deploy/secrets/api.token),
resolved from fa-server's Compose directory via `../../../deploy/secrets/api.token`.
The three parent traversals are `server → fa → integrations → Specter`.
Specter's API mounts the same host file at `/run/secrets/specter_api_token`.
Provision it using the existing Specter deployment procedure before startup; do not
create a different token for fa, copy it into an image, or expose it to the client.
Only this token is shared, not Specter's entire secret directory or encryption key.
This is a file-backed Compose secret, not an encrypted secret-management service:
protect the host file, its backups and Docker access, and ensure container readability.

## Credentials and production environment

Inject values through the deployment platform's secret store/protected environment.
Never commit credentials, paste them into logs, or hardcode them in Compose or frontend
build variables. The following variables must be present and nonempty for Compose:

| Variable | Purpose |
| --- | --- |
| `JWT_SECRET` | Strong signing secret for fa authentication and live tickets; no default |
| `SUPABASE_URL` | URL of the provisioned Supabase project |
| `SUPABASE_KEY` | Server-side key authorized for the existing users/assignment schema; never sent to browsers |
| `MINIO_ACCESS_KEY` | Existing MinIO credential or newly provisioned root username for this local stack |
| `MINIO_SECRET_KEY` | Matching strong MinIO secret; used by both server and MinIO |

The exact Supabase key variable is `SUPABASE_KEY`, not an invented
`SUPABASE_SERVICE_ROLE_KEY`. Provision the existing user/assignment schema and access
policies; do not apply the superseded organizations/camera-mapping migration.
Keep existing MinIO credentials when reusing its data unless deliberately rotating them.
Required interpolation replaces the old hardcoded MinIO development credentials.

Set `ALLOWED_ORIGINS` to the public frontend's exact HTTPS origin (or comma-separated
origins without surrounding spaces). The Compose default `http://localhost:5173` is
only a local development convenience, not a production origin. Server configuration
also supports `JWT_EXPIRES_IN` (default `7d`) and `BCRYPT_SALT_ROUNDS` (default `10`);
these optional settings need an explicit Compose override to reach the container.

## Operator rollout (not executed in this change)

1. Provision Specter's token, models, storage permissions and camera reachability per
   [Specter deployment](../../../../docs/deployment.md). Back up persistent data.
2. Supply the required fa credentials and production origin through protected deployment
   configuration. Choose the owner ID before creating data; changing it selects a
   different Specter namespace, not a migration of cameras or assignments.
3. Validate both Compose definitions quietly. For fa, use `docker compose config --quiet`
   from the server directory; for Specter select both Compose files with `-f` and use
   `config --quiet`. Never use unredacted `config` or `config --environment` in logs.
4. Deploy the Specter project first. Its migrations, API, NATS, camera manager and
   detector must be ready; the external network must already exist before fa starts.
5. Build/deploy fa-server as its own Compose project, retaining its default network.
   Cross-project readiness is not covered by fa's MongoDB/MinIO `depends_on` entries.
   Verify API access and NATS connectivity, not merely that the process listens.
6. Deploy the frontend separately. The current server Dockerfile does not build or copy
   the client. Same-origin hosting through a reverse proxy is recommended; optional
   `CLIENT_DIST_DIR` requires separately provisioning the client build and configuration.
7. Complete the acceptance checklist below before approving rollout.

## HTTP, realtime and live video

- Route application HTTP traffic under `/api`, including `/api/cameras`, `/api/alerts`,
  `/api/watchlists` and `/api/enrollment-batches`. Keep `/socket.io/` routed to fa-server
  with both polling and WebSocket upgrade support.
- Forward WebSocket upgrades for `/api/cameras/{id}/live/mse` as well as Socket.IO.
  Preserve query strings and set suitable streaming timeouts; redact live ticket query
  values from proxy/access logs. Use HTTPS/WSS at the public edge.
- The viewer authenticates `POST /api/cameras/{id}/live/ticket`; camera access is checked
  before a camera-bound, 60-second, one-use ticket is issued. It then connects to
  `/api/cameras/{id}/live/mse?ticket=…`. Each reconnect needs a fresh ticket. Only fa adds
  Specter's Bearer token on the upstream WebSocket.
- JPEG fallback uses authenticated `GET /api/cameras/{id}/live/frame.jpeg`.
  The client must fetch with its fa Authorization header and render a blob URL rather
  than put a service token or user JWT into an image URL. Responses are `no-store`.
- **Deviation from v2: HLS is NOT proxied by fa. The client implementation is MSE +
  authenticated JPEG fallback.** Do not advertise a working fa HLS endpoint, add an
  HLS.js requirement, or bypass authentication by pointing the browser at go2rtc.
- The current ticket replay cache is process-local and cleared on restart. Use one
  fa-server instance; multi-instance/global replay protection and restart-safe redemption
  need additional design and verification. One-use protection must not be claimed
  across replicas or process restarts.
- A successful camera start request is not a running camera: await status updates.
  Enrollment is asynchronous. An alert arriving over NATS can briefly return 404 from
  HTTP before persistence catches up; bounded refetch is needed.

## Production boundaries and pending acceptance

The supplied fa stack still publishes MongoDB and MinIO ports and has no TLS ingress;
MongoDB is not configured with authentication here. Restrict these ports to a trusted
host/network or use a hardened deployment override before production. Do not expose
Specter/NATS/go2rtc administration to browsers or the public internet. This deployment
wiring is not a complete production-hardening change.

Local validation: client production build and 220 regression tests passed; server
type checking and 47 tests passed (one email-delivery test skipped). Scoped client
lint passed. Full client lint retains 27 pre-existing errors and four warnings;
production build reports a large-bundle warning. These are not deployment acceptance.
Browser fixtures verified camera/watchlist navigation, dialogs, viewer guards and
390px layout without mutating backend records. Runtime checks below remain **pending**:

- Real token readability, Docker DNS/network connectivity and Supabase permissions.
- Watchlist/target CRUD, photo upload/read/delete and asynchronous enrollment updates.
- Camera CRUD, watchlist selection, start/stop and actual status delivery.
- Alert cursor/filter behavior, authorized snapshots, acknowledge/resolve persistence.
- Authenticated Socket.IO reconnect/refetch and room isolation by camera/role.
- MSE playback and authenticated JPEG fallback; expired, replayed, cross-camera and
  missing tickets denied; unauthorized JPEG/snapshot reads denied.
- Negative authorization checks for viewer/operator/admin and unassigned cameras,
  including direct API calls and WebSocket upgrades (not only hidden UI controls).
- Outage/restart behavior: HTTP state recovery without a Mongo alert copy or a promise
  of durable fa event replay; fresh live tickets after reconnect.

No containers were started for this documentation/deployment change. Consult the
[verification matrix](../../../../integration_plan_fa_specter.md#verification-matrix)
for the limited local validation evidence and remaining acceptance work.
