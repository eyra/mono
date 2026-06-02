FROM elixir:1.18.4-otp-27 AS builder

WORKDIR /workspace

ENV NODE_MAJOR=18
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
ARG PLATFORM=fly
ARG FORCE_SSL=true
# Compiles E2E support facilities (e.g. local payment simulator) into the
# build. Non-production only.
ARG ENABLE_E2E_SUPPORT=false

ENV BUNDLE=$BUNDLE
ENV VERSION=$VERSION
ENV PLATFORM=$PLATFORM
ENV FORCE_SSL=$FORCE_SSL
ENV ENABLE_E2E_SUPPORT=$ENABLE_E2E_SUPPORT

COPY mix.exs .
RUN mix deps.get

COPY . .
RUN scripts/build-frontend
RUN scripts/build-release

FROM debian:bookworm-slim
ARG VERSION
ARG GIT_COMMIT
ENV VERSION=$VERSION
ENV GIT_COMMIT=$GIT_COMMIT
ENV MIX_ENV=prod
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
# Gives `bin/core remote` a usable line editor (arrows/history/tab) over SSH.
ENV TERM=xterm-256color

LABEL org.opencontainers.image.revision=$GIT_COMMIT

RUN apt-get update && apt-get install -y \
    inotify-tools \
    libssl-dev \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

EXPOSE 8000

COPY --from=builder /workspace/$VERSION /opt/app

COPY ./scripts/predeploy /opt/app/bin
COPY ./scripts/docker-start-app /opt/app/bin

CMD ["/opt/app/bin/docker-start-app"]
