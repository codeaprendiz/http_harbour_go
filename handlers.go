package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

const (
	httpHeaderAppName    string = "X-App-Name"
	httpHeaderAppVersion string = "X-App-Version"
	defaultHttpTimeout   int    = 30 // in seconds
)

type customResponseWriter struct {
	writer http.ResponseWriter
	status int
	lenght int
}

func (crw *customResponseWriter) Header() http.Header {
	return crw.writer.Header()
}

func (crw *customResponseWriter) WriteHeader(statusCode int) {
	crw.status = statusCode
	crw.writer.WriteHeader(statusCode)
}

func (crw *customResponseWriter) Write(b []byte) (int, error) {
	if crw.status == 0 {
		crw.status = http.StatusOK
	}
	crw.lenght = len(b)

	return crw.writer.Write(b)
}

func httpLog(out io.Writer, nextHandlerFunc http.HandlerFunc) http.HandlerFunc {
	return func(responseWriter http.ResponseWriter, request *http.Request) {
		crw := &customResponseWriter{writer: responseWriter}
		defer func() { // defer is very important here, status and lenght in crw have not been populated yet, you get 0 0 in logs if you remove defer which is expected. Making it defer delays the execuation until the surrounding function completes and by that time these get populated as we are passing &customResponseWriter{writer: responseWriter} i.e. crw to nextHandlerFunc
			status := crw.status
			length := crw.lenght
			log.Println("[INFO]", request.Host, request.RemoteAddr, request.Method, request.URL.Path, request.Proto,
				status, length, request.UserAgent())
		}()
		nextHandlerFunc(crw, request)
	}

}

func addAppHeaders(status int, nextHandlerFunc http.HandlerFunc) http.HandlerFunc {
	return func(responseWriter http.ResponseWriter, request *http.Request) {
		responseWriter.Header().Set(httpHeaderAppName, "http_harbour")
		responseWriter.Header().Set(httpHeaderAppVersion, "0.1.2")
		responseWriter.WriteHeader(status)
		nextHandlerFunc(responseWriter, request)
	}
}

func httpDump(dumpString string) http.HandlerFunc {
	return func(responseWriter http.ResponseWriter, request *http.Request) {
		fmt.Fprintln(responseWriter, dumpString)
	}
}
