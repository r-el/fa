# Specter Dashboard

Web application and application server interface for the Specter edge vision engine.

Specter Dashboard operates as an application layer and BFF (Backend-for-Frontend) over Specter:
- **Client (`client/`)**: Web dashboard for operators and administrators (React 19, Vite, TanStack Query, Tailwind CSS).
- **Server (`server/`)**: Express API with Supabase auth/user management and an Anti-Corruption Layer (ACL) communicating with Specter's HTTP API and NATS JetStream event bus.
- **Specter Vision Engine**: Source of truth for cameras, watchlists, targets/photos, enrollment, and vision alerts.

---

## Workspace Structure

The project uses git submodules:
- `client/` -> [specter-client](https://github.com/r-el/specter-client)
- `server/` -> [specter-server](https://github.com/r-el/specter-server)

To clone recursively or initialize:
```bash
git submodule update --init --recursive
```

---

## Quick Start (Local Development)

### 1. Start Server (`server/`)
```bash
cd server
npm install
npm run dev
```
Runs on `http://localhost:12113` and connects to Specter API (`http://127.0.0.1:8000`) and NATS (`4222`).

### 2. Start Client (`client/`)
```bash
cd client
npm install
npm run dev
```
Runs on `http://localhost:5173` with Vite HMR.

---

## Architecture & Deployment

- **Deployment Guide**: See [docs/deploy/SPECTER_DEPLOY.md](docs/deploy/SPECTER_DEPLOY.md) for Docker Compose network wiring, shared secret token, and container environment variables.
