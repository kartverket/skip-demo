# Bruker clean nytt image 
FROM golang:1.25

WORKDIR /usr/src/app

# Laster ned deps
COPY ./app/go.mod ./app/go.sum ./
RUN go mod download

# Kopierer kildekoden og bygger applikasjonen
COPY ./app .
RUN go build -v -o /usr/local/bin/app ./...

# Setter bruker og gruppe
USER 150:150


#setter miljøvariabler
ENV GIN_MODE=release

# Starter appen
CMD ["app"]