FROM elixir:1.14.0 as builder

WORKDIR /workspace

ENV NODE_MAJOR 16

RUN set -x &&\
    mix local.hex --force &&\
    mix local.rebar --force &&\
    curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash - &&\
    apt-get install -y nodejs inotify-tools

RUN mix archive.install --force hex phx_new 1.5.5


ARG BUNDLE
ARG VERSION

ENV BUNDLE $BUNDLE
ENV VERSION $VERSION

COPY mix.exs .
RUN mix deps.get

COPY assets assets
COPY scripts scripts
COPY priv priv
RUN scripts/build-frontend

COPY . .
RUN scripts/build-release

FROM debian:bullseye-slim
ARG VERSION
ENV VERSION $VERSION

EXPOSE 443
EXPOSE 80

COPY --from=builder /workspace/$VERSION /opt/app

COPY scripts/migrate-and-start /opt/app/bin

CMD ["/opt/app/bin/migrate-and-start"]

