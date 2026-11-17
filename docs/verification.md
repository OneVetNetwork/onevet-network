# Verification results

Checked November 16, 2026 on Windows, Python 3.11.7 and Node 24.17.0.

Story: Home -> Browse Programs -> FastAPI -> Supabase published data -> organization details -> official assistance destination -> directory.

| Boundary | Result | Evidence and limits |
| --- | --- | --- |
| Frontend build | Passed | `npm run build` completed with Vite 8.3.5. |
| Backend startup | Passed | Uvicorn started; HTTP `/api/health` returned 200 with `status: ok` and `database_configured: false`. |
| API tests | Passed | 11 unittest cases: missing configuration, restricted keys, read-only routes, CORS, related records, filtering, ID validation, 404, Supabase HTTP headers, timeout and sanitized errors. These use mocked upstream responses. |
| Existing schema + seed | Passed locally | Executed the unchanged original migration and the complete seed twice in temporary PGlite PostgreSQL. Result: 5 organizations, 5 programs, 4 categories, 5 category links, 6 service-area rows, 5 eligibility summaries, with unchanged counts after rerunning. |
| Access policies | Passed locally | The original policies hide a test draft program. `anon` and `authenticated` lack INSERT/UPDATE/DELETE/TRUNCATE privileges on organizations/programs and SELECT on the checked private profile, assessment, referral, and saved-program tables. No policy changes were needed. |
| Real browser, no database config | Passed | Home buttons, Profile navigation, About navigation, unknown route, and detail deep link were exercised. Directory and detail pages visibly reported missing database configuration and rendered no fallback records. |
| Browser with seed-generated test responses | Passed | A temporary test harness served the production FastAPI app and mocked only the Supabase HTTP transport with rows produced by executing the actual seed. All 5 organizations, all 5 detail pages, Back to Directory, text/category search, empty results, and missing organization were exercised. This was not a hosted Supabase test. |
| Search behavior | Passed | `housing` finds 3 organizations because Operation Homefront's description mentions housing expenses. Selecting the Housing category finds the 2 programs classified as Housing. |
| Official destinations | Passed | All 5 assistance links matched the reviewed official pages/portals, used appropriate Apply vs How to Get Assistance labels, and targeted a new tab. A real click opened the VA application introduction in a new tab; the OneVet tab returned to the directory. No application was submitted. |
| Basic appearance | Passed | Browser computed styles: Arial, black text, pure white background, left alignment. No horizontal overflow at a 375px viewport. No console errors on the successfully loaded directory. |
| Credential handling | Passed locally | No actual `.env` or supplied Supabase credentials were available. Browser source receives only the backend API URL. Keys are backend environment values; secret/service-role keys are rejected. `.env` files and Python environments are ignored. |
| Hosted Supabase Data API | **Requires manual setup/check** | Project credentials were unavailable and no live queries or writes were performed. Add the project URL/public key, review/run the seed yourself, and execute the README smoke commands. Hosted RLS, Data API exposure, schema cache, and network reachability still need confirmation. |

All temporary test processes and the temporary embedded-PostgreSQL/browser fixture harness were removed after verification. They are not runtime dependencies or application fallbacks. The browser test harness did not write an environment file or change application configuration on disk. The original remote schema migration is unchanged.

No push, merge, deployment, or live database change was performed. There is no production hosting integration in this change.
