FROM node:23-alpine AS base

FROM base AS pnpm
RUN corepack enable pnpm

FROM pnpm AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml .
RUN --mount=type=cache,target=/root/.pnpm pnpm install --frozen-lockfile --prefer-offline

FROM pnpm AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

FROM base AS runner
WORKDIR /app
RUN addgroup -S -g 1001 nodejs
RUN adduser -S -u 1001 sveltekit
COPY --from=builder --chown=sveltekit:nodejs /app/build ./build
USER sveltekit
EXPOSE 3000
CMD ["node", "build"]
