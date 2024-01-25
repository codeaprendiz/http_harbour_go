package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

var (
	listenFlag  = flag.String("listen", ":8080", "Address and port to listen on")
	textFlag    = flag.String("text", "Welcome to http harbour go!", "text to put on the webpage")
	versionFlag = flag.Bool("version", false, "Display the version information")
	statusFlag  = flag.Int("status-code", 200, "HTTP response status code")

	stdoutW = os.Stdout
	stderrW = os.Stderr
)

func main() {
	flag.Parse()

	if *versionFlag {
		fmt.Fprintln(stdoutW, "1.0.0")
		os.Exit(0)
	}

	if len(flag.Args()) > 0 {
		fmt.Fprintf(stderrW, "Too many arguments!!!")
		os.Exit(127)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", httpLog(stdoutW, addAppHeaders(*statusFlag, httpDump(*textFlag))))

	server := &http.Server{
		Addr:    *listenFlag,
		Handler: mux,
	}

	serverCh := make(chan struct{})

	go func() {
		log.Println("[INFO] server is listening on : ", *listenFlag)
		err := server.ListenAndServe()

		log.Println("[ERR] : ", err)

		if err != http.ErrServerClosed {
			log.Fatalln("[ERR] server exited with ", err)
		}

		close(serverCh)
	}()

	signalCh := make(chan os.Signal, 1)
	signal.Notify(signalCh, os.Interrupt, syscall.SIGTERM)

	<-signalCh

	log.Println("[INFO] received interrupt, shutting down...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := server.Shutdown(ctx)
	if err != nil {
		log.Fatalln("[ERR] failed to shutdown server : ", err)
	}

	log.Println("[INFO] Shutting down duo to interrupt")
	os.Exit(2)
}
