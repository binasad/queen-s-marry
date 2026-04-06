# GitHub Pages Setup

This repo uses **GitHub Pages** with a root `index.html` as the entry point.

## Why index.html (not README.md)?

GitHub Pages **does not serve README.md as the index**. It requires `index.html` at the root (or in `/docs` if that folder is selected). Without it, you get **404 File Not Found**.

## Settings Checklist

1. **Repo** → **Settings** → **Pages** (left sidebar)
2. Under **Build and deployment**:
   - **Source**: Deploy from a branch
   - **Branch**: `main` (or your default branch)
   - **Folder**: `/(root)`
3. Save and wait 1–5 minutes for deployment
4. Site URL: `https://<username>.github.io/queen-s-marry/`

## Files at Root

- `index.html` — Landing page (required for Pages to work)
- `README.md` — Shown on the repo’s main GitHub page, not on Pages
