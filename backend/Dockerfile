FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json ./
COPY prisma/schema.prisma ./prisma/schema.prisma
# Prisma CLI is a locked development dependency used by migrate deploy.
RUN PRISMA_SKIP_POSTINSTALL_GENERATE=true npm ci --include=dev --no-audit --no-fund \
    && ./node_modules/.bin/prisma generate \
    && npm cache clean --force

COPY prisma/migrations ./prisma/migrations
COPY src ./src
COPY test ./test
USER node
EXPOSE 3000
CMD ["sh", "-c", "./node_modules/.bin/prisma migrate deploy && exec npm start"]
