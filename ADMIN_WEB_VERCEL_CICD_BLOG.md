## Admin Web CI/CD to Vercel – What We Built and How We Fixed It

This post documents how the **Merry Queen** admin dashboard (Next.js 14) is deployed to production on **Vercel** using **GitHub Actions**, and the issues we hit along the way.

The live admin dashboard runs at:  
**[https://queen-s-marry.vercel.app](https://queen-s-marry.vercel.app/)**

---

### 1. Goal and Repository Layout

The repository is a monorepo:

- `admin-web/` – Next.js 14 admin dashboard (TypeScript, Tailwind, Zustand, Axios, Firebase)
- `.github/workflows/admin-web.yaml` – CI/CD pipeline for the admin panel

The goal:

- On **every push to `main` that touches `admin-web/**`**:
  - Install dependencies
  - Build the Next.js app in CI
  - Deploy prebuilt artifacts to **Vercel Production**

---

### 2. GitHub Actions → Vercel Pipeline

The pipeline lives in `.github/workflows/admin-web.yaml` and roughly does:

1. **Checkout & Node setup**
   - `actions/checkout@v4`
   - `actions/setup-node@v4` with Node 20.15.0 and npm cache pointing to `./admin-web/package-lock.json`

2. **Install Vercel CLI & dependencies**
   - `npm install --global vercel`
   - `npm ci` in `./admin-web`

3. **Link to Vercel project**
   - `vercel pull --yes --environment=production --token $VERCEL_TOKEN`
   - Uses `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` and `VERCEL_TOKEN` from **GitHub Secrets**

4. **Build & Deploy**
   - `vercel build --prod --token $VERCEL_TOKEN`
   - `vercel deploy --prebuilt --prod --token $VERCEL_TOKEN`

This uses Vercel’s **Build Output API**: `vercel build` writes to `.vercel/output`, and `vercel deploy --prebuilt` uploads that directory directly to production.

---

### 3. Problem #1 – `admin-web/admin-web/package.json` (Wrong Working Directory)

**Symptom (CI logs):**

```text
Error: ENOENT: no such file or directory, open '/home/runner/work/queen-s-marry/queen-s-marry/admin-web/admin-web/package.json'
```

**Root cause:**

- In Vercel, the project root directory was already configured as `admin-web`.
- In GitHub Actions we initially ran Vercel commands from **inside** `admin-web` (either via `cd admin-web` or `working-directory: ./admin-web`).
- Vercel combined both and looked for:
  - `<repo-root>/admin-web` (project root)  
  - plus another `admin-web` from the working directory  
  - → `admin-web/admin-web/package.json` (which doesn’t exist).

**Fix:**

We aligned the working directory with how Vercel expects to find the project:

- Option A (current setup): **run Vercel from the repo root** and let Vercel use its configured `rootDirectory = admin-web`.
- Option B (also valid): have `rootDirectory = .` in Vercel and run CLI from `./admin-web`.

We chose **Option A**, so the workflow no longer `cd`’s into `admin-web` for Vercel, and the CLI looks for `admin-web/package.json` once, not twice.

---

### 4. Problem #2 – “No Output Directory named `public`” (Misconfigured `vercel.json`)

Once the path issue was fixed, we hit another error:

```text
Error: No Output Directory named "public" found after the Build completed.
```

**What this meant:**

- Vercel thought our project was a generic **static site** (output in `public/`), not a **Next.js app** that uses `.next` / `.vercel/output`.
- We tried to “help” with a `vercel.json`:

```json
{
  "//": "Ensure Vercel treats this as a Next.js app and uses the correct build output directory.",
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "outputDirectory": ".vercel/output"
}
```

That backfired:

- `buildCommand` overrode Vercel’s default Next.js builder logic.
- `outputDirectory` told Vercel to expect `.vercel/output` from our custom command, but `next build` writes to `.next`, not `.vercel/output`.

**Fix:**

We simplified `vercel.json` down to:

```json
{
  "framework": "nextjs"
}
```

Letting Vercel handle:

- Running the correct build internally for Next.js
- Producing `.vercel/output` in the right format

Once we removed the custom `outputDirectory` and `buildCommand`, `vercel build` succeeded and the prebuilt artifacts were deployed.

---

### 5. Problem #3 – WebSocket Errors During Static Generation

During `next build`, we saw errors like:

```text
Error: 🔌 WebSocket connection error: websocket error
  _url: 'ws://localhost:5000/socket.io/?EIO=4&transport=websocket'
  code: 'ECONNREFUSED'
```

**Why this happens:**

- The admin uses `socket.io-client` to connect to the backend (`ws://localhost:5000` in development).
- During static generation / page data collection, some code paths attempted to open that WebSocket connection.
- In CI there is no backend on `localhost:5000`, so the connection was refused.

**Impact:**

- These errors are noisy but do **not** break the build; Next.js still generated all routes, and `vercel build` completed.

**Possible mitigations (if needed):**

- Guard the WebSocket initialization with a runtime check:
  - Only connect when running in the browser (`typeof window !== 'undefined'`).
  - Or only enable WebSockets when an env flag like `NEXT_PUBLIC_ENABLE_WS` is true.

For now, they’re acceptable warnings and don’t block deployment.

---

### 6. Final Production Setup

- **Production URL:**  
  `https://queen-s-marry.vercel.app/` (admin dashboard root; `app/page.tsx` redirects to `/dashboard`)

- **Vercel project settings:**
  - Git repo: `https://github.com/binasad/queen-s-marry`
  - Root Directory: `admin-web`
  - Framework: auto-detected / forced to Next.js via `vercel.json`
  - Environment variables:
    - `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, `VERCEL_TOKEN` (used by GitHub Actions)
    - Optional: `NEXT_PUBLIC_BACKEND_URL` or `NEXT_PUBLIC_API_URL` for backend rewrites

- **GitHub Actions:**
  - Trigger: push to `main` affecting `admin-web/**`
  - Steps:
    - Checkout
    - Setup Node 20.15.0
    - `npm ci` in `admin-web/`
    - `vercel pull` (production)
    - `vercel build --prod`
    - `vercel deploy --prebuilt --prod`

The result is a **fully automated CI/CD pipeline**: every change to `admin-web` on `main` is built and deployed to Vercel Production, with issues like misaligned paths and output directories now resolved.

