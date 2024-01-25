# Metadata about this makefile and position
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
CURRENT_DIR := $(patsubst %/,%,$(dir $(realpath $(MKFILE_PATH))))

# Ensure GOPATH
GOPATH ?= $(HOME)/go
GOBIN ?= $(GOPATH)/bin

# Tags specific for building
GOTAGS ?=

# Number of procs to use
GOMAXPROCS ?= 4

# Get the project metadata
GOVERSION := $(shell go version | awk '{print $3}' | sed -e 's/^go//')
PROJECT := $(CURRENT_DIR:$(GOPATH)/src/%=%)
OWNER := codeaprendiz
NAME := http_harbour_go
REVISION ?= $(shell git rev-parse --short HEAD)
VERSION := $(shell cat "${CURRENT_DIR}/version/VERSION")
TIMESTAMP := $(shell date)

# Get local ARCH; on Intel Mac, 'uname -m' returns x86_64 which we turn into amd64.
# Not using 'go env GOOS/GOARCH' here so 'make docker' will work without local Go install.
ARCH     ?= $(shell A=$$(uname -m); [ $$A = x86_64 ] && A=amd64; echo $$A)
OS       ?= $(shell uname | tr [[:upper:]] [[:lower:]])
PLATFORM ?= $(OS)/$(ARCH)
DIST     ?= dist/$(PLATFORM)
BINARY_PATH      ?= $(DIST)/$(NAME)


# Default os-arch combination to build
XC_OS ?= darwin # linux windows
XC_ARCH ?= arm64 # amd64
XC_EXCLUDE ?=

# List of ldflags
LD_FLAGS ?= \
	-s \
	-w \
	-X 'github.com/codeaprendiz/http_harbour_go/version.Version=${VERSION}' \
	-X 'github.com/codeaprendiz/http_harbour_go/version.GitCommit=${REVISION}' \
	-X 'github.com/codeaprendiz/http_harbour_go/version.Timestamp=${TIMESTAMP}'

# List of tests to run
TEST ?= ./...

version:
	@echo $(VERSION)
.PHONY: version


dist:
	mkdir -p $(DIST)

xc: dist
	@echo "==> Cross-compiling for all platforms\n\n"
	@$(foreach GOOS, $(XC_OS),\
		$(foreach GOARCH, $(XC_ARCH),\
			echo "Building for $(GOOS)/$(GOARCH)" && \
			ARCH=${GOARCH} OS=${GOOS} $(MAKE) bin;))
.PHONY: xc


build:
	CGO_ENABLED=0 go build \
		-a \
		-o="$(BINARY_PATH)" \
		-ldflags "$(LD_FLAGS)" \
		-tags "$(GOTAGS)" \
		-trimpath \
		-buildvcs=false
.PHONY: build

bin: dist
	@echo "==> Building with ENVs : \n BINARY_PATH : ${BINARY_PATH} \n OS : ${OS} \n ARCH : ${ARCH} \n"
	@GOARCH=$(ARCH) GOOS=$(OS) CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(LD_FLAGS)" -o $(BINARY_PATH)
.PHONY: bin



# dev builds and installs the project locally.
dev: bin
	cp $(BINARY_PATH) $(GOBIN)/$(BIN_NAME)
.PHONY: dev

# Docker Stuff.
export DOCKER_BUILDKIT=1
BUILD_ARGS = BIN_NAME=http_harbour_go
TAG        = ${OWNER}/$(NAME):local
PORT_FLAG       = -p 8080:8080
BA_FLAGS   = $(addprefix --build-arg=,$(BUILD_ARGS))
DOCKERFILE = Dockerfile
FLAGS      = --platform $(PLATFORM) -f ${DOCKERFILE} --tag $(TAG) $(BA_FLAGS)

# Set OS to linux for all docker/* targets.
docker: OS = linux

docker: bin
	@echo "==> Building Docker image for ${PLATFORM}"
	docker build ${FLAGS} .
	docker push ${TAG}
	@echo 'Image built; run "docker run --rm ${PORT_FLAG} ${TAG}" to try it out.'
.PHONY: docker




# clean removes any previous binaries
clean:
	@rm -rf "${CURRENT_DIR}/dist/"
.PHONY: clean

# Test target to echo paths
echo-paths:
	@echo "MKFILE_PATH: $(MKFILE_PATH)"
	@echo "CURRENT_DIR: $(CURRENT_DIR)"
	@echo "GOFILES : $(GOFILES)"
	@echo "GOTAGS : $(GOTAGS)"
	@echo "GOMAXPROCS : $(GOMAXPROCS)"
	@echo "GOVERSION : $(GOVERSION)"
	@echo "PROJECT : $(PROJECT)"
	@echo "OWNER : $(OWNER)"
	@echo "NAME : $(NAME)"
	@echo "REVISION : $(REVISION)"
	@echo "VERSION : $(VERSION)"
	@echo "TIMESTAMP : $(TIMESTAMP)"
	@echo "ARCH : $(ARCH)"
	@echo "OS : $(OS)"
	@echo "PLATFORM : $(PLATFORM)"
	@echo "DIST : $(DIST)"
	@echo "BINARY_PATH : $(BINARY_PATH)"
