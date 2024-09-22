FROM ghcr.io/gleam-lang/gleam:v1.4.1-erlang-alpine

WORKDIR /build

COPY . /build

# Check Rebar3 installation
RUN which rebar3 || echo "Rebar3 not found"
RUN rebar3 --version || echo "Rebar3 version check failed"

# Compile the project
RUN gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]