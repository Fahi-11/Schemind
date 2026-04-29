# -------- FRONTEND BUILD --------
FROM node:18-alpine AS frontend-builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy frontend source
COPY src ./src
COPY index.html ./
COPY vite.config.ts ./
COPY tsconfig*.json ./
COPY tailwind.config.js ./
COPY postcss.config.js ./

# Build frontend
RUN npm run build


# -------- BACKEND BUILD --------
FROM node:18-alpine AS backend

WORKDIR /app

# Install backend deps
COPY backend/package*.json ./backend/
RUN cd backend && npm install

# Copy backend code
COPY backend ./backend


# -------- FINAL IMAGE --------
FROM node:18-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs

# Copy backend
COPY --from=backend /app/backend ./backend

# Copy built frontend into backend/public
COPY --from=frontend-builder /app/dist ./backend/public

WORKDIR /app/backend

RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]