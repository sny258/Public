# stage 1:for building the app
# taking node as base image
FROM node:latest as node							
# creating working directory inside image to execute commands
WORKDIR /app
# copy all the current directory files into image
COPY . .							
RUN npm 
# this will create dist/demo-app folder which will be used in stage 2
RUN npm run build --prod
# or RUN ng vuild --prod (both are same)

# stage 2: for running the app
FROM nginx:alpine
COPY --from=node /app/dist/demp-app /usr/share/nginx/html