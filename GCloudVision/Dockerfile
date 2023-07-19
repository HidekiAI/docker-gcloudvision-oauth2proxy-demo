# Use the official Rust image as the base image
FROM rust:latest as builder

# Set up your Rust application directory
WORKDIR /usr/src/my-rust-app

# Copy the Rust application source code and necessary files
COPY . .

# Build the Rust application
RUN cargo build --release

# Start a new image with a smaller base image
FROM debian:buster-slim

# Copy the binary from the builder stage
COPY --from=builder /usr/src/my-rust-app/target/release/my_rust_app /usr/local/bin/my_rust_app

# Set the Rust application entrypoint
CMD ["/usr/local/bin/my_rust_app"]

