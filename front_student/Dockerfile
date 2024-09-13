# First stage: Build the application
FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
RUN yarn install
# Set the environment variable for OpenSSL legacy support
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN yarn build

# Second stage: Serve the application
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/build .
RUN yarn global add serve
CMD ["serve", "-p", "80", "-s", "."]

