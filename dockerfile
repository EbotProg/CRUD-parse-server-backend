

# Build the docker image with `npm run docker:build`.
# Tip: Modify "docker:build" options in project.json to change docker build args.
#
# Run the container with `npm run docker:up`.

############################################################
# Build stage
############################################################
FROM node:jod-alpine AS build

WORKDIR /tmp

# Copy package.json AND package-lock.json first (layer caching)
COPY package*.json ./

# Install exactly the locked versions (incl. dev deps needed for the build).
# The cache mount keeps downloaded packages between builds → fewer downloads.
RUN --mount=type=cache,target=/root/.npm npm ci --no-audit --no-fund

# Copy the source and build
COPY . .
RUN npm run build

# Remove dev-only packages; what's left is exactly the production set
RUN npm prune --omit=dev

############################################################
# Release stage
############################################################
FROM node:jod-alpine AS release

WORKDIR /parse-server

# npm is not needed at runtime (the app starts with node) and carries vulnerabilities
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

# Copy the finished app from the build stage: no second install, no network
COPY --from=build --chown=node:node /tmp/node_modules ./node_modules
COPY --from=build --chown=node:node /tmp/dist ./dist
COPY --from=build --chown=node:node /tmp/package.json ./package.json

VOLUME ["/parse-server/cloud"]

EXPOSE 1337

USER node

# Same as the "start" script in package.json, without npm
CMD ["node", "dist/index.js"]
#-------------------------------------------

# Builder stage
# FROM node:20.19.1-alpine AS builder

# WORKDIR /usr/src/parse

# COPY package*.json .

# RUN npm install

# COPY . .

# RUN npm run build

# # latest supported node version when this Dockerfile was written
# FROM node:20.19.1-alpine

# WORKDIR /usr/src/parse

# # Copy only the required files from the builder stage
# COPY --from=builder /usr/src/parse/node_modules ./node_modules
# COPY --from=builder /usr/src/parse/dist ./
# COPY --from=builder /usr/src/parse/public ./public

# VOLUME ["/usr/src/parse/cloud", "/usr/src/parse/logs"]

# EXPOSE 1337

# CMD ["node", "index.js"]
