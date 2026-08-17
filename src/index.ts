import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import express from 'express';
import { ParseServer } from 'parse-server';

const PORT = Number(process.env.PORT) || 1337;
const PARSE_MOUNT = process.env.PARSE_MOUNT || '/parse';

const DATABASE_URI = process.env.DATABASE_URI || 'mongodb://localhost:27017/crud_dev';
const APP_ID = process.env.APP_ID || 'myAppId';
const MASTER_KEY = process.env.MASTER_KEY || 'myMasterKey';
const MAINTENANCE_KEY = process.env.MAINTENANCE_KEY || 'myMaintenanceKey';
const SERVER_URL = process.env.SERVER_URL || `http://localhost:${PORT}${PARSE_MOUNT}`;

// Let Parse Server require the cloud file itself, so it loads it at the right
// point in its own startup (after Parse.initialize), which is what makes
// Parse.Cloud.beforeSave etc. register correctly. Resolve to the compiled
// dist/cloud/main.js when it exists (production), otherwise fall back to the
// TypeScript source (dev, running under `tsx`).
const compiledCloudPath = path.join(__dirname, 'cloud', 'main.js');
const cloudPath = fs.existsSync(compiledCloudPath)
  ? compiledCloudPath
  : path.join(__dirname, 'cloud', 'main.ts');

const parseServer = ParseServer({
  databaseURI: DATABASE_URI,
  appId: APP_ID,
  masterKey: MASTER_KEY,
  maintenanceKey: MAINTENANCE_KEY,
  serverURL: SERVER_URL,
  allowClientClassCreation: true,
  cloud: cloudPath,
});

async function start(): Promise<void> {
  await parseServer.start();

  const app = express();

  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  app.use(PARSE_MOUNT, parseServer.app);

  app.listen(PORT, () => {
    console.log(`Parse Server running on port ${PORT}`);
    console.log(`REST API mounted at ${SERVER_URL}`);
  });
}

start().catch((err) => {
  console.error('Failed to start Parse Server:', err);
  process.exit(1);
});
