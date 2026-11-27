import { access } from 'node:fs/promises';
import { URL, fileURLToPath } from 'node:url';
import { Router } from 'express';
import { draftYaml } from './openapi-draft.js';

const contractFile = fileURLToPath(new URL('../../../api-contract/openapi.draft.yaml', import.meta.url));
export const docs = Router();

docs.get('/openapi.yaml', async (_request, response, next) => {
  response.type('application/yaml');
  try {
    await access(contractFile);
  } catch (error) {
    if (error.code === 'ENOENT') {
      // Backend-only Docker images do not contain the repository-level contract.
      return response.send(draftYaml);
    }
    return next(error);
  }
  response.sendFile(contractFile);
});

docs.get('/', (_request, response) => {
  response.type('html').send(`<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SonLokma API · Dokümantasyon</title>
</head>
<body>
  <div id="app"><a href="/docs/openapi.yaml">SonLokma OpenAPI taslağını aç</a></div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/scalar-api-reference/1.36.2/standalone.js"
    integrity="sha256-KMCSu74i2zQja42jSEM2HVhoCG2VINV2v5IwVzNPIso=" crossorigin="anonymous"></script>
  <script>
    if (window.Scalar) {
      Scalar.createApiReference('#app', { url: '/docs/openapi.yaml', withDefaultFonts: false });
    }
  </script>
</body>
</html>`);
});
