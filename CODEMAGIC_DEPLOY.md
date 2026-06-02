# Codemagic deployment

This project is prepared for Codemagic with Android and Web workflows.

## Environment

The workflows pass the production backend URL through `API_BASE_URL`:

```text
https://backend-dialysis-record-system-spring.onrender.com
```

Override the `API_BASE_URL` variable in Codemagic if the backend URL changes.

## Workflows

- `android-debug-apk`: builds a debug APK for manual testing.
- `android-release-aab`: builds a signed Android App Bundle for Google Play.
- `web-release`: builds Flutter Web and exports `build/web` as an artifact.

## Android signing

For `android-release-aab`, create an Android code signing identity in Codemagic named:

```text
dialysis_record_keystore
```

Codemagic will inject `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, and `CM_KEY_PASSWORD` during the build.
