# Render web deployment

This deploys Flutter Web as a Docker Web Service on Render.

## Render settings

- Service type: `Web Service`
- Runtime: `Docker`
- Dockerfile path: `Dockerfile`
- Root directory: leave empty

## Build argument

Set this Docker build arg in Render:

```text
API_BASE_URL=https://backend-dialysis-record-system-spring.onrender.com
```

If Render does not show Docker build args in your plan/UI, the Dockerfile already defaults to the current Render backend URL.

## Deploy

Push to `main`, then create or redeploy the Render Web Service.

After Render gives you the frontend URL, add it to the backend CORS config/environment.
