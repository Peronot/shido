import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import resourceRoutes from './modules/resourceRoutes.js';
import authRoutes from './routes/auth.js';
import healthRoutes from './routes/health.js';

const app = express();
const port = Number(process.env.PORT || 4000);
const host = process.env.HOST || '0.0.0.0';

app.use(cors());
app.use(express.json());

app.use('/api', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/resources', resourceRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(port, host, () => {
  console.log(`Shido backend running on http://${host}:${port}`);
});
