# Shido Backend (Node.js + PostgreSQL)

## 1. Create database in pgAdmin/query tool
Run:

```sql
CREATE DATABASE "Shido App";
```

## 2. Apply schema
Open DB `Shido App` then run file:
- `backend/database/sql/02_schema.sql`

## 3. Configure backend

```bash
cd backend
cp .env.example .env
```

Edit `.env` and set your real postgres password:

```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/Shido%20App
PORT=4000
```

## 4. Run backend

```bash
npm install
npm run dev
```

## CRUD endpoints for all 20 tables
Base pattern:
- `GET /api/:resource`
- `GET /api/:resource/:id`
- `POST /api/:resource`
- `PUT /api/:resource/:id`
- `DELETE /api/:resource/:id`

Example resources:
- `users`
- `roles`
- `permissions`
- `clubs`
- `players`
- `games`
- `rounds`
- `payments`
- `audit_logs`
- ... and all others from your list

Health check:
- `GET /api/health`

---

## Online Deploy (Free)

### A) Backend (Render free)

1. Push project to GitHub
2. Render -> New -> Blueprint -> select repo
3. Render will read `backend/render.yaml`
4. Set required secrets in Render:
   - `DATABASE_URL`
   - `JWT_SECRET`
5. Deploy and copy backend URL, example:
   - `https://shido-backend.onrender.com/api`

### B) Database (Free)

Use Neon/Supabase free Postgres and paste connection string into `DATABASE_URL`.

### C) Flutter Web (Free)

Build with online API:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://YOUR-BACKEND-URL/api
```

Then host `build/web` on Netlify/Vercel/Cloudflare Pages free plan.
