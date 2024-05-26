FROM node:22-alpine as base

FROM base as deps-extractor
WORKDIR /app
RUN apk add --no-cache jq
COPY package.json .
RUN jq '{dependencies, devDependencies, peerDependencies} | with_entries(select( .value != null ))' package.json > deps.json

FROM base as pnpm
RUN corepack enable
RUN corepack install -g pnpm@9

FROM pnpm as deps
WORKDIR /app
COPY --from=deps-extractor /app/deps.json ./package.json
COPY pnpm-lock.yaml .
RUN --mount=type=cache,target=/root/.pnpm pnpm install --frozen-lockfile --prefer-offline

FROM pnpm as builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm exec svelte-kit sync && pnpm build

FROM base as runner
WORKDIR /app
RUN addgroup -S -g 1001 nodejs
RUN adduser -S -u 1001 sveltekit
COPY --from=builder --chown=sveltekit:nodejs /app/build ./build
USER sveltekit
EXPOSE 3000
CMD ["node", "build"]
