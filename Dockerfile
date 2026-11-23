ARG BUILDPLATFORM

# Build the manager binary
FROM --platform=${BUILDPLATFORM} docker.io/golang:1.26.11@sha256:4165ee6bf3b7811fd7b40373290405c83d0167dcb87ee5f29c427cdcef45ff8f AS builder
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
WORKDIR /

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY pkg/ pkg/

# Build
RUN echo "Building on ${BUILDPLATFORM}, target GOOS=${TARGETOS} GOARCH=${TARGETARCH}" && CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o /builds/manager main.go

FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

# Alpine publishes package fixes faster than it rebuilds this image, so the digest above can pin a
# build whose OS packages already have a fix waiting in the repository. Applying the upgrades keeps
# the published image free of findings a user can act on, at the cost of the package set being
# resolved at build time rather than fixed by the digest alone.
RUN apk --no-cache upgrade

WORKDIR /
COPY --from=builder /builds/manager .
USER 65532:65532
WORKDIR /
ENTRYPOINT ["./manager"]
