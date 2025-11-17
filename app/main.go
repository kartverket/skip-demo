package main


import "github.com/gin-gonic/gin"


func main() {
	router := gin.Default()

	router.StaticFile("/", "./static/index.html")

	// Liveness probe
	router.GET("/healthz", func(c *gin.Context) {
		c.JSON(c.Writer.Status(), gin.H{"status": "ok"})
	})

	// Readiness probe
	router.GET("/readyz", func(c *gin.Context) {
		c.JSON(c.Writer.Status(), gin.H{"status": "ok"})
	})


	router.Run(":8080")
}