# Latest Rust stable release as base image
# Planner stage
FROM rust:1.47 AS planner

# Switch to app as working dir. Will create if does not exist
WORKDIR app

# We only pay the installation cost once, 
# it will be cached from the second build onwards
# To ensure a reproducible build consider pinning 
# the cargo-chef version with `--version X.X.X`
RUN cargo install cargo-chef

# Copy all the files from the current directory to Docker image
COPY . .

# Compute a lock-like file for project
RUN cargo chef prepare --recipe-path recipe.json


# Planner stage
FROM rust:1.47 AS cacher

# Switch to app as working dir. Will create if does not exist
WORKDIR app

# Install cargo chef again
RUN cargo install cargo-chef

# Copy recipe file that will build our dependencies
COPY --from=planner /app/recipe.json recipe.json

# Build our project dependencies, not our application! 
RUN cargo chef cook --release --recipe-path recipe.json


FROM rust:1.47 AS builder
WORKDIR app
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo
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
