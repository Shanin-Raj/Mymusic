# Stage 1: Runtime
FROM node:22-slim

# Install system dependencies for music processing
# We install python3, ffmpeg, and curl
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --production --silent || npm install --production --silent

# Copy application source
COPY backend/ ./backend/

# Create necessary directories for cache, downloads, and images
RUN mkdir -p /app/backend/cache /app/backend/downloads /app/images && \
    chmod -R 777 /app/backend/cache /app/backend/downloads /app/images

# Set environment variables
ENV NODE_ENV=production
ENV PORT=7860

# Change working directory to backend for execution
WORKDIR /app/backend

# Expose port
EXPOSE 7860

# Start the application
CMD ["node", "server.js"]
