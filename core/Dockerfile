FROM elixir:1.14.0 as builder

WORKDIR /workspace

ENV NODE_MAJOR 18
ENV MIX_ENV prod
ENV SSL_PROXIED true

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

COPY . .
RUN scripts/build-frontend
RUN scripts/build-release

FROM debian:bullseye-slim
ARG VERSION
ENV VERSION $VERSION
ENV MIX_ENV prod

RUN apt-get update && apt-get install -y inotify-tools

EXPOSE 8000

COPY --from=builder /workspace/$VERSION /opt/app

COPY ./scripts/migrate-and-start /opt/app/bin

CMD ["/opt/app/bin/migrate-and-start"]

