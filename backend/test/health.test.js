import assert from 'node:assert/strict';
import { URL } from 'node:url';
import { once } from 'node:events';
import { after, before, test } from 'node:test';
import { app } from '../src/app.js';

let server;
let baseUrl;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close(error => error ? reject(error) : resolve());
  });
});

test('GET /health reports that the service is running', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /application\/json/);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('POST /health is not registered', async () => {
  const response = await fetch(`${baseUrl}/health`, { method: 'POST' });
  assert.equal(response.status, 404);
});

test('Scalar documentation points to a locally served OpenAPI contract', async () => {
  const response = await fetch(`${baseUrl}/docs`);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /text\/html/);
  const html = await response.text();
  assert.match(html, /Scalar\.createApiReference/);
  const specPath = html.match(/url: '([^']+)'/)[1];
  assert.equal(specPath, '/docs/openapi.yaml');
  const spec = await fetch(new URL(specPath, baseUrl));
  assert.equal(spec.status, 200);
  assert.match(spec.headers.get('content-type'), /application\/yaml/);
  const yaml = await spec.text();
  assert.match(yaml, /^openapi: 3\./m);
  assert.match(yaml, /^  title: SonLokma API$/m);
  assert.match(yaml, /^  \/auth\/otp\/send:/m);
});
