# Steg 1: Bygg applikasjonen
FROM golang:1.27 AS builder

WORKDIR /usr/src/app

# Laster ned avhengigheter først for bedre caching av Docker-lag
COPY ./app/go.mod ./app/go.sum ./
RUN go mod download

# Kopierer kildekoden og bygger en statisk binærfil
COPY ./app .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /usr/local/bin/app .

# Steg 2: Minimalt kjøretidsimage (scratch anbefales på SKIP)
FROM scratch

WORKDIR /app

# CA-sertifikater, slik at applikasjonen kan gjøre utgående HTTPS-kall (scratch har ingen)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Kopierer binærfilen og statiske filer fra builder-steget
COPY --from=builder /usr/local/bin/app /app/app
COPY --from=builder /usr/src/app/static /app/static

# Skiperator kjører alle containere som UID/GID 150, uten capabilities og med
# skrivebeskyttet rot-filsystem (kun /tmp er skrivbart). Vi setter det samme her
# slik at containeren oppfører seg likt lokalt som på SKIP.
USER 150:150

# Setter miljøvariabler
ENV GIN_MODE=release

EXPOSE 8080

# Starter appen
ENTRYPOINT ["/app/app"]
