# Shido App Deploy Guide

## 1) Backend on Render
Create a `Web Service` from this repo with:

- Name: `shido-backend`
- Branch: `main`
- Runtime: `Docker`
- Root Directory: `backend`
- Dockerfile Path: `./Dockerfile`
- Instance: `Free`

Environment Variables:

- `DATABASE_URL` = your Neon PostgreSQL connection string
- `JWT_SECRET` = long random secret
- `NODE_ENV` = `production`
- `HOST` = `0.0.0.0`
- `PORT` = `10000`

Deploy and verify:

- Open: `https://YOUR-RENDER-URL.onrender.com/api/health`

Expected response:

```json
{"status":"ok"}
```

## 2) Build APK locally (manual)

```bash
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-RENDER-URL.onrender.com/api
```

APK path:

`build/app/outputs/flutter-apk/app-release.apk`

## 3) Build APK via GitHub Actions (automatic)

Workflow added: `.github/workflows/android-release.yml`

Option A: Manual run

1. GitHub -> Actions -> `Build Android APK`
2. Click `Run workflow`
3. Enter `api_base_url` as `https://YOUR-RENDER-URL.onrender.com/api`
4. Download artifact `app-release-apk`

Option B: Release auto-attach

1. Create a GitHub release (`v1.0.0`)
2. Workflow builds APK and attaches it to the release automatically

## 4) Share with users

Share release link:

`https://github.com/Peronot/shidoapp/releases/latest`

Users can download and install `app-release.apk`.