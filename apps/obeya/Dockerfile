FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# The image context holds only apps/obeya, so the staleness check (which reads contracts/) runs in `npm run build` and tests, not here.
RUN npx nuxt build

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
