# Build the Loom React application, then serve only its production output.
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
ARG VITE_API_BASE=/api
ENV VITE_API_BASE=$VITE_API_BASE
ARG VITE_GOOGLE_CLIENT_ID=
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID
ARG VITE_DESKTOP_AGENT_DOWNLOAD_URL=
ENV VITE_DESKTOP_AGENT_DOWNLOAD_URL=$VITE_DESKTOP_AGENT_DOWNLOAD_URL
RUN npm run build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
# Railway routes to $PORT (often 8080); Compose still uses 80.
CMD ["sh", "-c", "sed -i \"s/listen 80;/listen ${PORT:-80};/\" /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
