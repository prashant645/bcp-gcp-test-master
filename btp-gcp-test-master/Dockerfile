# Base image pinning
# ------------------
# Promotion by digest only guarantees "what you tested is what ships" if the
# build itself is reproducible. An unpinned tag lets a later build pull a
# different base image. Pin both FROM lines to a digest:
#
#   docker buildx imagetools inspect node:22-alpine --format '{{.Manifest.Digest}}'
#   # then: FROM node:22-alpine@sha256:<digest> AS test
#
# TODO(pin): not pinned yet - see docs/branching-strategy.md "Limitations".
FROM node:22-alpine AS test
WORKDIR /app
COPY package.json server.js ./
COPY test ./test
RUN npm test

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=3000
COPY --from=test /app/package.json /app/server.js ./
USER node
EXPOSE 3000
CMD ["node", "server.js"]
