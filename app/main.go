package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

const defaultPort = "8080"

// newRouter bygger HTTP-ruteren. Den er skilt ut fra main() slik at den kan testes.
func newRouter() *gin.Engine {
	router := gin.Default()

	router.StaticFile("/", "./static/index.html")

	// Liveness probe
	router.GET("/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// Readiness probe
	router.GET("/readyz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	return router
}

func main() {
	// Konfigurasjon via miljøvariabler, slik at samme image kan brukes i alle miljøer.
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           newRouter(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	// Kubernetes sender SIGTERM når en pod skal stoppes. Vi lar pågående
	// forespørsler fullføre før prosessen avslutter (grace period er 30 sekunder på SKIP).
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("Lytter på %s", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Serveren stoppet uventet: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("Mottok stoppsignal, avslutter...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Kunne ikke avslutte pent: %v", err)
	}
}
