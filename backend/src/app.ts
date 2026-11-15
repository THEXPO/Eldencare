import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';
import apiRoutes from './routes';
import { swaggerDocument } from './swagger';
import { errorHandler } from './middleware/errorHandler';

export function createApp(): express.Application {
  const app = express();

  // Security and core middleware
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(cors({ origin: true, credentials: true }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Swagger Documentation
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'EldenCare Backend API', timestamp: new Date().toISOString() });
  });

  // REST API v1
  app.use('/api/v1', apiRoutes);

  // Centralized Error Handling
  app.use(errorHandler);

  return app;
}
