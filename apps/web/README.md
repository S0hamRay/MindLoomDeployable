# Loom Web

Main Loom web application. It includes organization onboarding, the dashboard,
AI question answering, uploads, organization and knowledge graphs, and connected
apps. The web app talks to the Loom API in `apps/api` for auth, directory
import, dashboard, and connected apps.

## Stack

- React 18 + TypeScript
- Vite
- Tailwind CSS (shadcn/ui-style primitives in `src/components/ui`)
- Framer Motion (page + element animations)
- Lucide icons
- Zustand (onboarding state, persisted to `localStorage`)
- React Router

## Getting started

```bash
npm install
npm run dev      # http://localhost:5173
```

Other scripts:

```bash
npm run build    # type-check + production build to dist/
npm run preview  # preview the production build
npm run lint     # tsc --noEmit
```

## Flow & routes

```
/setup              Welcome
/setup/signin       Sign in (returning users)
/setup/org          Create Organization
/setup/csv          Optional admin-only employee directory import
/dashboard          Main app (requires session)
```

Creating an organization goes directly to the dashboard. Administrators then
connect company knowledge from **Apps**, optionally add an employee directory
from **Organization**, and invite employees later. Members do not see workspace
connection or organization-creation controls.

## Production / staging build

`VITE_API_BASE` and `VITE_GOOGLE_CLIENT_ID` are compile-time Vite env vars.
Rebuild the image (or `npm run build`) after changing them.

| Setup | `VITE_API_BASE` |
|-------|-----------------|
| Local Vite dev | omit (uses `/api` proxy) |
| Docker Compose | `/api` (default; nginx proxies to `api:8000`) |
| Separate HTTPS API host | `https://api.example.com` |

Production builds **throw at startup** if `VITE_API_BASE` is missing — never ship a silent `localhost` fallback.

### HTTPS deploy checklist

1. Terminate TLS at the edge (Caddy, Traefik, cloud LB). Do not serve HTTPS UI calling an HTTP API (mixed content).
2. Bake `VITE_API_BASE` to `/api` (same-origin proxy) or the public `https://` API origin.
3. Set API `FRONTEND_URL` and `CORS_ALLOWED_ORIGINS` to the public web origin(s).
4. Register GIS authorized JavaScript origins and OAuth redirect URIs on the public HTTPS hosts (`GOOGLE_WORKSPACE_OAUTH_REDIRECT_URI`, Microsoft, Zoom).
5. Set production secrets (`SESSION_SECRET`, `TOKEN_ENCRYPTION_KEY`, webhook secrets) with `APP_ENV=production`.
