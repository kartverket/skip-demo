# Steg 1: Bygg applikasjonen
FROM golang:1.25 AS builder

WORKDIR /usr/src/app

# Laster ned avhengigheter først for bedre caching av Docker-lag
COPY ./app/go.mod ./app/go.sum ./
RUN go mod download

# Kopierer kildekoden og bygger en statisk binærfil
COPY ./app .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -v -o /usr/local/bin/app ./...

# Steg 2: Minimalt kjøretidsimage (scratch anbefales på SKIP)
FROM scratch

WORKDIR /app

# Kopierer binærfilen og statiske filer fra builder-steget
COPY --from=builder /usr/local/bin/app /app/app
COPY --from=builder /usr/src/app/static /app/static

# Setter bruker og gruppe (påkrevd av Skiperator / Pod Security Standards på SKIP)
USER 150:150

# Setter miljøvariabler
ENV GIN_MODE=release

EXPOSE 8080

# Starter appen
ENTRYPOINT ["/app/app"]
