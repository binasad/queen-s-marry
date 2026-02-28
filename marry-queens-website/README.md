# Merry Queens Salon – Marketing Website

Static marketing site for Merry Queens Salon. Built with Bootstrap 5, HTML, and CSS.

## Features

- Responsive design
- SEO meta tags, Open Graph, schema.org
- Bootstrap Icons
- Sitemap & robots.txt

## Deployment

### Vercel (recommended)

1. Create a new project at [vercel.com](https://vercel.com) and import this repo
2. Set **Root Directory** to `marry-queens-website`
3. Deploy (no build step needed)
4. After deploy, update `robots.txt` and `sitemap.xml` with your production URL

### GitHub Pages

1. In repo Settings → Pages, set source to **GitHub Actions**
2. Use the `static` workflow or push the `marry-queens-website` folder to a `gh-pages` branch

### CI/CD (optional)

The workflow `.github/workflows/marry-queens-website.yaml` deploys to Vercel on push. Add these secrets:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `MARRY_QUEENS_WEBSITE_PROJECT_ID` (create a separate Vercel project for this site)

## Local preview

Open `index.html` in a browser or run:

```bash
npx serve marry-queens-website
```
