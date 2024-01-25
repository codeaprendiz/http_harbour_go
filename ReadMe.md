# http_harbour_go

## Local

```bash
$ go mod init http_harbour_go
go: creating new go.mod: module http_harbour_go
go: to add module requirements and sums:
        go mod tidy

go build
```

### Run

```bash
# Terminal 1
$ ./http_harbour_go -listen=:9090 -text='Hello, World' -status-code=201
2024/01/21 22:25:01 [INFO] server is listening on :  :9090

# Terminal 2
$ curl localhost:9090 -v                  
*   Trying 127.0.0.1:9090...
* Connected to localhost (127.0.0.1) port 9090 (#0)
> GET / HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/8.1.2
> Accept: */*
> 
< HTTP/1.1 201 Created
< X-App-Name: http_harbour
< X-App-Version: 0.1.2
< Date: Sun, 21 Jan 2024 18:25:24 GMT
< Content-Length: 13
< Content-Type: text/plain; charset=utf-8
< 
Hello, World
* Connection #0 to host localhost left intact

# Terminal 1, updated
$ ./http_harbour_go -listen=:9090 -text='Hello, World' -status-code=201
2024/01/21 22:25:01 [INFO] server is listening on :  :9090

2024/01/21 22:25:24 [INFO] localhost:9090 127.0.0.1:51519 GET / HTTP/1.1 201 13 curl/8.1.2
```

## Makefile

```bash
# For cleanup
make clean

# Build locally
make build

# Move to $PATH directory, ensure path is added to .zshrc or .bashrc
make dev

# Build and push to registy
make docker
```
