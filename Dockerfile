FROM node:20-slim

WORKDIR /app

# Copy package files from root
COPY package*.json ./

# Install dependencies
RUN npm ci --production 2>/dev/null || npm install --production

# Copy backend source
COPY backend/ ./backend/

# Create cache directory
RUN mkdir -p /app/backend/cache

# Set working directory to backend
WORKDIR /app/backend

# Expose port (Cloud Run sets PORT env var)
EXPOSE 8080

# Start the server
CMD ["node", "server.js"]
