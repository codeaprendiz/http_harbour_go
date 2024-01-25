FROM gcr.io/distroless/static-debian12:nonroot as default

# TARGETOS and TARGETARCH are set automatically when --platform is provided.
ARG TARGETOS
ARG TARGETARCH
ARG BIN_NAME

LABEL name="http_harbour_go" 

COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /

EXPOSE 8080/tcp

ENTRYPOINT ["/http_harbour_go"]