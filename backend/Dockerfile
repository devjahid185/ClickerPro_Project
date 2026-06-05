# Clicker Pro API — production image
# Works on any container host (Render, Railway, Fly.io, Cloud Run, etc.).
#
# Build:  docker build -t clicker-pro-api .
# Run:    docker run -p 5000:5000 --env-file .env clicker-pro-api
FROM node:20-slim AS base

# Prisma needs OpenSSL at runtime.
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install deps first for better layer caching. `postinstall` runs
# `prisma generate`, so copy the schema before `npm ci`.
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev

# App source.
COPY . .

ENV NODE_ENV=production
ENV PORT=5000
EXPOSE 5000

# Apply any pending migrations, then start the server.
CMD ["npm", "run", "start:prod"]
