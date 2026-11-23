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

FROM alpine:3.24.3@sha256:b3413572228e34bd1c9245f5565e6cd127005655e8a7899aef33d8e83255c9e6

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
