FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:24-alpine
RUN apk add --no-cache git
WORKDIR /app
ENV OBEYA_IN_CONTAINER=1 OBEYA_HOST=0.0.0.0 OBEYA_PORT=3000
COPY --from=build /app/.output ./.output
COPY bin ./bin
COPY package.json ./
USER node
EXPOSE 3000
CMD ["node", "bin/start.mjs"]
