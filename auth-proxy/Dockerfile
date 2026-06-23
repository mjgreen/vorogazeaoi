FROM golang:1.22-alpine AS build

WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/vorogaze-auth-proxy .

FROM alpine:3.20

RUN adduser -D -H -u 10001 appuser
USER appuser

EXPOSE 8088

COPY --from=build /out/vorogaze-auth-proxy /usr/local/bin/vorogaze-auth-proxy

ENTRYPOINT ["/usr/local/bin/vorogaze-auth-proxy"]
