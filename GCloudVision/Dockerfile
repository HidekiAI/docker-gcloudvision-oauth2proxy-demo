# Use the official Rust image as the base image
FROM rust:latest as builder

# Set up your Rust application directory
WORKDIR /usr/src/my_rust_app
#RUN mkdir -p /usr/local/bin
#RUN mkdir -p /usr/src/my_rust_app/target/release/

# Copy src to WORKDIR so that we can 'cargo build' on the image (native)
RUN mkdir -p src
COPY src/* ./src/
COPY *.toml .

# Build the Rust application ON the target-host (simply put, it is so that when built, it will generate Linux-based target (i.e. "myexec.exe" versus "myexec" generated files))
RUN cargo build --release --verbose

# Start a new image with a smaller base image
FROM debian:latest

# Copy the binary from the builder stage - note that src file MUST be absolute paths
COPY --from=builder /usr/src/my_rust_app/target/release/my_rust_app* /usr/local/bin/

# Set the Rust application entrypoint - note that you'll need to be root privilege to run this for it binds to a listening port
CMD ["/usr/local/bin/my_rust_app"]

