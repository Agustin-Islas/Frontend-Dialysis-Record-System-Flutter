# Cloudflare Pages deployment

This deployment is independent from Codemagic.

## Cloudflare Pages settings

- Framework preset: `None`
- Root directory: leave empty
- Build command:

```bash
bash cloudflare-pages-build.sh
```

- Build output directory:

```text
build/web
```

## Environment variables

Set these in Cloudflare Pages:

```text
API_BASE_URL=https://api.your-domain.com
FLUTTER_VERSION=stable
SKIP_DEPENDENCY_INSTALL=1
```

`API_BASE_URL` must point to the backend URL served from Oracle Cloud.

## SPA routing

The file `web/_redirects` makes direct browser navigation work for Flutter Web routes.
