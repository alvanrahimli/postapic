FROM alpine:3.16 AS base
RUN apk add \
  --update \
  --no-cache \
  vips

FROM golang:1.19-alpine3.16 AS sdk
RUN apk add \
  --update \
  --no-cache \
  --repository http://dl-3.alpinelinux.org/alpine/edge/community \
  --repository http://dl-3.alpinelinux.org/alpine/edge/main \
  vips-dev \
  alpine-sdk

FROM sdk AS deps
WORKDIR /src
COPY go.mod .
COPY go.sum .
RUN go mod download

FROM deps AS build
COPY . .
RUN go build -o /server

FROM base AS app
WORKDIR /app
EXPOSE 8080
COPY ./static /app/static
COPY ./templates /app/templates
COPY --from=build /server /app/server

CMD [ "/app/server" ]
