# Latest Rust stable release as base image
FROM rust:1.47

# Switch to app as working dir. Will create if does not exist
WORKDIR app

# Copy all the files from the current directory to Docker image
COPY . .

# Set env variable for sqlx offline mode
ENV SQLX_OFFLINE true

# Build the binary
RUN cargo build --release

# Set env variable for app environment
ENV APP_ENVIRONMENT production

# Launch binary when container is run
ENTRYPOINT ["./target/release/app"]
