# -----------------------------
# Stage 1 — Install dependencies
# -----------------------------

FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev


# -----------------------------
# Stage 2 — Production image
# -----------------------------

FROM node:20-alpine

WORKDIR /app

# Create secure non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy application files
COPY src ./src
COPY public ./public
COPY package.json ./

# Build metadata
ARG GIT_SHA=local
ARG BUILD_DATE=local

ENV GIT_SHA=${GIT_SHA}
ENV BUILD_DATE=${BUILD_DATE}

# Permissions
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]
