FROM node:24-alpine
WORKDIR /app
COPY package.json server.mjs index.html app.js styles.css ./
ENV PORTAL_HOST=0.0.0.0 PORTAL_PORT=8082 PORTAL_DATABASE=/data/portal.sqlite
EXPOSE 8082
CMD ["node", "server.mjs"]
