# Build image
FROM swift:6.2-jammy AS build

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy SharedModels package (CfP types shared with iOS)
COPY ./SharedModels ./SharedModels

# Copy Server package manifest
COPY ./Server/Package.swift ./Server/Package.swift

# Create minimal Server source to resolve dependencies
RUN mkdir -p Server/Sources/Server && \
    echo "@main struct App { static func main() {} }" > Server/Sources/Server/main.swift

# Resolve dependencies (cached unless Package.swift changes)
WORKDIR /build/Server
RUN swift package resolve

# Now copy actual Server source code (overwrites placeholder)
COPY ./Server/Sources ./Sources
COPY ./Server/Tests ./Tests

# Build Server with release configuration
RUN swift build -c release --static-swift-stdlib \
    -Xlinker -ljemalloc

# Switch to staging area
WORKDIR /staging

# Copy main executable
RUN cp "$(swift build --package-path /build/Server -c release --show-bin-path)/Server" ./

# Copy Swift runtime libraries
RUN find -L "$(swift build --package-path /build/Server -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \; 2>/dev/null || true

# Production image
FROM ubuntu:jammy

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      libjemalloc2 \
      ca-certificates \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /staging /app

# Copy static assets (images)
COPY ./Website/Assets/images ./Public/images
COPY ./Server/Public/cfp ./Public/cfp

ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

EXPOSE 8080

ENTRYPOINT ["./Server"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
