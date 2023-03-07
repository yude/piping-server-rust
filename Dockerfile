# NOTE: Multi-stage Build

FROM nwtgck/rust-musl-builder:1.67.1 as build

# Install tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-arm64 /tini-static
RUN sudo chmod +x /tini-static

# Copy to Cargo setting and change the owner
COPY --chown=rust:rust Cargo.toml Cargo.lock ./
# Build empty project for better cache
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release --locked && rm -r src

# Copy to current directory and change the owner
COPY --chown=rust:rust . ./
# Build
RUN cargo build --release --locked

FROM scratch
LABEL maintainer="yude <i@yude.jp>"

# Copy executables
COPY --from=build /tini-static /tini-static
COPY --from=build /home/rust/src/target/arm64-unknown-linux-musl/release/piping-server /piping-server
# Run a server
ENTRYPOINT [ "/tini-static", "--", "/piping-server" ]
