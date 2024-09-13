# Use Node.js version 20 Alpine image
FROM node:20-alpine

# Install necessary packages
RUN apk add --no-cache python3 py3-pip make g++ \
    && ln -sf python3 /usr/bin/python

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and yarn.lock files
COPY package.json yarn.lock ./

# Install dependencies with increased network timeout
RUN yarn install --network-timeout 1000000

# Copy the rest of your application code
COPY . .

# Copy and set permissions for the entrypoint script
COPY entrypoint.sh /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh

# Add a non-root user and switch to it
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose port 3000 for external access
EXPOSE 3000

# Set the entrypoint to start your application
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

