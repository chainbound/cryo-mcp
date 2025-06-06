# ---- Build Stage ----
FROM node:22-slim AS build

WORKDIR /app

# Install system dependencies for Rust and build tools
RUN apt-get update && apt-get install -y curl build-essential pkg-config libssl-dev ca-certificates git

# Install Rust and Cargo
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install cryo using Cargo
RUN cargo install --git https://github.com/paradigmxyz/cryo.git --locked

# Copy package files
COPY package.json ./package.json
COPY pnpm-lock.yaml ./pnpm-lock.yaml
COPY tsconfig.json ./tsconfig.json

RUN npm install -g pnpm && pnpm install --frozen-lockfile

# Copy source files
COPY src ./src

# Build the project
RUN pnpm run build

# ---- Production Stage ----
FROM node:22-slim AS prod
WORKDIR /app

ENV NODE_ENV=production

# Install system dependencies for cryo
RUN apt-get update && apt-get install -y libssl-dev ca-certificates curl

# Copy cryo binary from build stage
COPY --from=build /root/.cargo/bin/cryo /usr/local/bin/cryo

# Copy package files
COPY package.json ./package.json
COPY pnpm-lock.yaml ./pnpm-lock.yaml

# Install production dependencies
RUN npm install -g pnpm && pnpm install --frozen-lockfile --prod

# Copy built application
COPY --from=build /app/dist ./dist

# Copy static files
COPY index.html ./index.html
COPY static ./static

RUN useradd -m appuser
USER appuser

EXPOSE 3000
CMD ["node", "dist/index.js"] 