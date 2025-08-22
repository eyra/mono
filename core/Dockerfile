FROM elixir:1.17.0-otp-27 AS builder

WORKDIR /workspace

ENV NODE_MAJOR=22
ENV MIX_ENV=prod
ENV SSL_PROXIED=true

RUN set -x &&\
    mix local.hex --force &&\
    mix local.rebar --force &&\
    curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

RUN apt-get update && apt-get install -y \
    locales \
    curl \
    git \
    nodejs \
    build-essential \
    unzip \
    automake \
    autoconf \
    libssl-dev \
    libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

ARG BUNDLE
ARG VERSION

ENV BUNDLE=$BUNDLE
ENV VERSION=$VERSION

COPY mix.exs .
RUN mix deps.get

COPY . .
RUN scripts/build-frontend
RUN scripts/build-release

FROM debian:bookworm-slim
ARG VERSION
ENV VERSION=$VERSION
ENV MIX_ENV=prod

RUN apt-get update && apt-get install -y inotify-tools libssl-dev

EXPOSE 8000

COPY --from=builder /workspace/$VERSION /opt/app

COPY ./scripts/migrate-and-start /opt/app/bin

CMD ["/opt/app/bin/migrate-and-start"]
