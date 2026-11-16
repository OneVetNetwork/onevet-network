# Vercel Services configuration

Use the existing [onevet-network-csusm project](https://vercel.com/thiagolin3-1231/onevet-network-csusm), connected to `OneVetNetwork/onevet-network`. Do not create a new project, reconnect the repository, move the domains, or reinstall the Supabase integration.

This configuration follows the current [`services` model](https://vercel.com/docs/services), which is in beta. It does not use the older `experimentalServices` / `routePrefix` configuration.

## Configuration files

- The repository-root `vercel.json` declares a Vite frontend rooted at `frontend/` and a FastAPI backend rooted at `backend/`, with ASGI entrypoint `main:app`.
- Frontend dependencies install with `npm ci`; `npm run build` creates `dist` inside the frontend service.
- The Python service uses its existing `requirements.txt`. It does not run a persistent Uvicorn server or need Docker.
- `.vercelignore` excludes local environment files (including examples), virtual environments, dependencies, build artifacts, logs, and local tool state from CLI uploads. It does not remove files already tracked in Git.

## Routing

| Request | Destination |
| --- | --- |
| `/api/health`, `/api/organizations`, `/api/organizations/123`, `/api/programs`, `/api/categories` | FastAPI; original `/api/` prefix is preserved |
| `/api/anything-else` | FastAPI's 404, not the React HTML page |
| `/docs`, `/openapi.json` | FastAPI documentation and schema |
| `/`, `/programs`, `/profile`, `/about`, `/organizations/123` | Frontend service; its SPA rewrite serves `index.html` for deep links |
| Existing `/assets/*` files | Frontend static build assets |

The API rules precede the frontend catch-all. The SPA fallback belongs inside the frontend service so it cannot swallow API requests. See [Services routing](https://vercel.com/docs/services/routing) and the [service configuration reference](https://vercel.com/docs/services/config-reference).

The current React application already defaults to same-origin `/api/*` requests in production and `http://127.0.0.1:8000` in Vite development. No application-code or CORS changes are needed for this configuration.

## Manual dashboard setup before a future deployment

No dashboard settings are changed by editing these files. In the **existing** project's Settings > Build and Deployment:

1. Set **Root Directory** to the repository root (clear `frontend` if it is set). Both service folders and the root `vercel.json` must be visible. `rootDirectory` is a dashboard setting, not a `vercel.json` property.
2. Clear the old project-wide Vite preset: select **Other** / automatic detection at the project level. The `services` declaration selects Services mode; each service explicitly declares its own Vite or FastAPI framework. Do not add a top-level `framework` to `vercel.json` or use the older Experimental Services setup.
3. Disable old project-wide Build Command, Install Command, Output Directory, and Development Command overrides if present. Build settings belong to the services. The frontend settings are declared in `vercel.json`; let FastAPI use its framework defaults.
4. Leave the Git connection, production branch, domains, integration, and deployment protection as they are. No DNS changes are needed.

The connected project currently reports its framework as Vite. The connected read API did not return the Root Directory or build override values, so verify those fields manually rather than assuming they are already correct.

In Settings > Environment Variables:

- Keep the integration-provided **`SUPABASE_URL`** and **`SUPABASE_PUBLISHABLE_KEY`** available to the backend for the environments you intend to use. Their names are already configured for Development, Preview, and Production; no key values need to be copied into code or into `vercel.json`.
- The backend uses the public read role and existing RLS policies. It rejects service-role/secret keys; it does not use the integration's database password or privileged keys.
- Leave **`VITE_API_BASE_URL` unset** in Preview and Production so each deployment calls its own backend at the same origin. In particular, do not set it to localhost or append `/api` (the application already includes that prefix).
- Do not introduce `VITE_SUPABASE_*` variables. Vite exposes only `VITE_*` values to client code by default; keep database configuration on the server.

These are setup instructions only. Do not choose Deploy, Redeploy, or Promote until deployment is authorized. Pushing to the connected repository can automatically trigger a Vercel build; no push is needed to review this configuration.

## Local development and checks

Keep using the existing two-terminal setup from the repository root:

```powershell
# Terminal 1 (after the backend environment/dependencies have been configured)
.\backend\.venv\Scripts\python.exe -m uvicorn main:app --app-dir backend --reload --host 127.0.0.1 --port 8000
```

```powershell
# Terminal 2
Set-Location frontend
npm run dev -- --host 127.0.0.1 --port 5173 --strictPort
```

Existing local `frontend/.env` may keep `VITE_API_BASE_URL=http://127.0.0.1:8000`. Do not upload it. This Services configuration does not change the standard Vite development workflow.

Build and API checks, without deploying:

```powershell
# From repository root
.\backend\.venv\Scripts\python.exe -m unittest backend.test_api -v
Set-Location frontend
npm run build
```

After a future authorized deployment, verify `/api/health`, `/api/organizations`, `/docs`, direct navigation and refresh on `/programs` and `/organizations/{existing-id}`, and `/api/not-a-route` returning JSON 404. Confirm requests stay on the deployment origin. These hosted checks require deployment and are intentionally deferred.

## Validation performed

- Validated `vercel.json` against the current schema fetched from `https://openapi.vercel.sh/vercel.json`.
- Checked service root folders, backend entrypoint/dependency files, 11 ingress path cases, and the frontend-only SPA fallback.
- `npm run build` passed with Vite 8.3.5. The production bundle contains no localhost API URL.
- All 11 existing API tests passed, including public-key handling, CORS, published-data queries, errors, and read-only routes.
- Inspected environment-variable names and target environments through the connected Vercel API without decrypting key values. Both required backend variables are already present.

These are local/schema checks, not an executed Vercel Services build or a hosted Supabase connection test. No deployment, push, merge, domain change, integration change, database write, or dashboard setting update was performed for this configuration-only request.
