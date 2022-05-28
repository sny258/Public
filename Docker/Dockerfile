#stage 1
FROM node:latest as node
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build --prod
# or RUN ng vuild --prod (both are same)

#stage 2
FROM nginx:alpine
COPY --from=node /app/dist/demp-app /usr/share/nginx/html
EXPOSE 8080