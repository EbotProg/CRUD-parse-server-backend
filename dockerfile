

# Build the docker image with `npm run docker:build`.
# Tip: Modify "docker:build" options in project.json to change docker build args.
#
# Run the container with `npm run docker:up`.

# ############################################################
# # Build stage
# ############################################################

FROM node:jod-alpine3.20 AS build

WORKDIR /tmp

# Copy package.json first to benefit from layer caching
COPY package*.json .

# Install without scripts
RUN npm install

# Copy src to have config files for install
COPY . .

# Run build step
RUN npm run build

RUN npm cache clean --force


############################################################
# Release stage
############################################################

FROM node:jod-alpine3.20 AS release

WORKDIR /parse-server

# RUN addgroup --system parse && \
#     adduser --system -G parse parse

# Copy the content of the build stage output to the working directory
# COPY --from=builder /tmp/node_modules ./node_modules
COPY --from=build /tmp/dist/ ./

# Copy the package.json file
COPY --from=build /tmp/package.json package.json

# Install packages
RUN npm install --omit=dev 
# \
#     && npm cache clean --force 

VOLUME ["/parse-server/cloud", "/parse-server/logs"]

EXPOSE 1337

# Clean node cache
RUN npm cache clean --force             

CMD [ "npm", "start" ]

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
