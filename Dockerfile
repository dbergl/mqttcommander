FROM golang:1-bookworm AS build
RUN useradd -u 1000 worker
WORKDIR /app
COPY go.mod ./

# Use cache mounts to speed up the installation of existing dependencies
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

# Copy the entire application source code
COPY . .

# Compile the application during build and statically link the binary
#    -tags netgo \
RUN go build \
    -a -tags "release" \
    -ldflags='-s -w -linkmode external -extldflags "-static"' \
    -o MqttCommander

FROM scratch

COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /app/MqttCommander /MqttCommander
USER worker

VOLUME data
ENV MQTTC_CONFIG_PATH=data
ENTRYPOINT ["/MqttCommander"]
