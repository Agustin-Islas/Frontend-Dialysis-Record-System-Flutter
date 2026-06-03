# GitHub Actions web deploy

This deploys Flutter Web to Cloudflare Pages on every push to `main`.

Codemagic remains untouched and can still build Android.

## Required GitHub secrets

Create these in the frontend repository:

```text
API_BASE_URL=https://api.your-domain.com
CLOUDFLARE_API_TOKEN=...
CLOUDFLARE_ACCOUNT_ID=...
CLOUDFLARE_PAGES_PROJECT_NAME=dialysis-record
```

## Cloudflare setup

1. Create a Cloudflare Pages project.
2. Use any temporary setup if Cloudflare asks for build settings.
3. Keep the project name and put it in `CLOUDFLARE_PAGES_PROJECT_NAME`.
4. Create an API token with permission to edit Cloudflare Pages.

After this, every `git push origin main` builds and deploys `build/web`.
