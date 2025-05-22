# ======================
# Builder Stage
# ======================
FROM debian:12 AS builder

WORKDIR /root

RUN apt-get update && apt-get install -y \
    locales \
    curl \
    git \
    build-essential \
    unzip \
    automake \
    autoconf \
    libssl-dev \
    libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
ENV PATH="/root/.asdf/bin:/root/.asdf/shims:${PATH}"

RUN asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

COPY .tool-versions /root/.tool-versions
RUN asdf install
RUN asdf reshim

RUN mix local.hex --force && mix local.rebar --force
RUN chmod -R a+rX /root/.asdf

# ======================
# Dev Stage
# ======================
FROM builder AS dev

COPY ./core /app/core
WORKDIR /app/core

RUN mix assets.install
RUN mix deps.get
RUN mix assets.build

CMD [ "mix","run"]

# ======================
# Release stage
# ======================

FROM dev AS build_release
ARG MIX_ENV=${MIX_ENV:-prod}
ENV BUNDLE=next
ARG VERSION

RUN ./scripts/build-frontend && ./scripts/build-release
RUN echo "Release build info:" && \
    echo "VERSION: $VERSION" && \
    echo "MIX_ENV: $MIX_ENV" && \
    echo "Contents of release directory:" && \
    ls -l /app/core/${VERSION} && \
    echo "Disk usage:" && \
    du -sh /app/core/${VERSION}


# =======================
# Prod Stage
# =======================

FROM debian:12-slim AS prod

RUN apt-get update && apt-get install -y \
      libssl-dev libncurses-dev tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG APP_NAME=core
ARG VERSION

ENV HOME=/app \
    PORT=4000 \
    APP_NAME=core

COPY --from=build_release /app/core/${VERSION} ./

RUN mkdir /home/next/uploads -p

ENTRYPOINT ["/app/bin/core"]
CMD ["start"]

