# Latest Rust stable release as base image
# Builder stage
FROM rust:1.47 AS builder

# Switch to app as working dir. Will create if does not exist
WORKDIR app

# Copy all the files from the current directory to Docker image
COPY . .

# Set env variable for sqlx offline mode
ENV SQLX_OFFLINE true

# Build the binary
RUN cargo build --release

# Runtime stage
FROM debian:buster-slim AS runtime

# set working dir
WORKDIR app

# Install OpenSSl - it is dynamically linked in some dependencies
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the builder environment
# to our runtime environment
COPY --from=builder /app/target/release/app app

# We need the configurtion files for runtime
COPY configuration configuration

# Set env variable for app environment
ENV APP_ENVIRONMENT production

# Launch binary when container is run
ENTRYPOINT ["./app"]
