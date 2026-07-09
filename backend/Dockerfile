# Stage 1: Build web frontend
FROM node:20-alpine AS web-builder
WORKDIR /web
COPY web/package*.json ./
RUN npm ci
COPY web/ .
RUN npm run build

# Stage 2: Backend runtime
FROM node:20-alpine
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY backend/ .
COPY --from=web-builder /web/dist /web/dist

EXPOSE 3000
CMD ["node", "src/app.js"]
