import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import prisma from './config/prisma.js';
import subscriptionRoutes from './routes/subscriptionRoutes.js';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// HTTP middleware
app.use(cors());
app.use(express.json());
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(503).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: err.message,
      timestamp: new Date().toISOString(),
    });
  }
});

app.get('/', (req, res) => {
  res.status(200).json({
    name: 'Subscart API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      subscription: '/api/subscription',
      slotAvailability: '/api/subscription/slots/availability?targetDate=YYYY-MM-DD',
      reschedule: 'POST /api/subscription/reschedule',
    },
  });
});

// Mount domain routes
app.use('/api/subscription', subscriptionRoutes);

// 404 and Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Subscart server running on port ${PORT}`);
  console.log(`Health check: http://0.0.0.0:${PORT}/health`);
  console.log(`Subscription API: http://0.0.0.0:${PORT}/api/subscription`);
});

export default app;
