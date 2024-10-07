FROM golang:1.23.2-alpine AS builder

WORKDIR /app
COPY main.go go.mod ./

RUN go get -u github.com/lib/pq
RUN CGO_ENABLED=0 go build ./

# Использование другого контейнера с собранным кодом
FROM scratch

COPY --from=builder /app/myserver /

CMD ["/myserver"]