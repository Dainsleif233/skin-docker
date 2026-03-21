FROM node:22-alpine AS builder
LABEL maintainer="dainsleif@yeah.com"
ARG BRANCH
WORKDIR /app

RUN apk add --no-cache make sqlite-dev
RUN wget https://github.com/Dainsleif233/janus/archive/refs/heads/docker/${BRANCH}.zip -O /tmp/janus.zip \
    && unzip /tmp/janus.zip -d /tmp/janus \
    && rm /tmp/janus.zip \
    && find /tmp/janus/janus-docker-${BRANCH} -mindepth 1 -maxdepth 1 -exec mv {} . \;

RUN npm i \
    && npx prisma generate \
    && npm run build \
    && npm i --omit=dev \
    && cp -r ./src/prisma ./dist/

FROM node:22-alpine
WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/.env.example ./
COPY --chmod=0755 entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
VOLUME ["/app/.env", "/app/oauth-private.key"]
