FROM node:18-alpine as build-stage
WORKDIR /app
COPY package.json .
COPY pnpm-lock.yaml .
RUN npm install -g pnpm
RUN pnpm install
COPY . .
RUN pnpm run build
FROM nginx:latest as production-stage
COPY --from=build-stage /app/dist /app
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
