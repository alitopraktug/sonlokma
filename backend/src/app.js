import express from 'express';

import { docs } from './docs/routes.js';

export const app = express();
app.disable('x-powered-by');

app.use('/docs', docs);

app.get('/health', (_request, response) => {
  response.json({ status: 'ok' });
});
