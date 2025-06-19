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

# Install asdf-vm and Erlang/Elixir/Node.js plugins
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
ENV PATH="/root/.asdf/bin:/root/.asdf/shims:${PATH}"

RUN asdf plugin-add erlang   https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin-add elixir   https://github.com/asdf-vm/asdf-elixir.git && \
    asdf plugin-add nodejs   https://github.com/asdf-vm/asdf-nodejs.git

COPY .tool-versions /root/.tool-versions
RUN asdf install && asdf reshim

# Install Hex/Rebar locally so mix deps.get works non-interactively
RUN mix local.hex --force && mix local.rebar --force

# Ensure asdf folders are world-readable for downstream stages
RUN chmod -R a+rX /root/.asdf


# ======================
# Dev Stage (with cached deps)
# ======================
FROM builder AS dev

WORKDIR /app/core

# 1) Copy dependency-related files first (for maximum caching)
COPY core/mix.exs core/mix.lock ./

# 2) Install and compile dependencies (cached until mix files change)
RUN mix deps.get
RUN mix deps.compile

# 3) Copy asset dependency files
COPY core/assets/package.json core/assets/package-lock.json ./assets/

# 4) Install npm dependencies (cached until package files change)
RUN cd assets && npm install

# 5) Copy configuration files (these rarely change)
COPY core/config/ ./config/

# 6) Copy assets directory
COPY core/assets/ ./assets/

# 7) Copy other necessary files
COPY core/priv/ ./priv/
COPY core/bundles/ ./bundles/
COPY core/frameworks/ ./frameworks/
COPY core/systems/ ./systems/
COPY core/.formatter.exs core/.credo.exs core/.bundle.ex ./

# 8) Copy source code (this changes most frequently, so put it last)
COPY core/lib/ ./lib/
COPY core/test/ ./test/

# 9) Build assets
RUN mix assets.build

CMD ["mix", "run"]


# ======================
# Release Stage  
# ======================
FROM dev AS build_release

ARG MIX_ENV=${MIX_ENV:-prod}
ENV BUNDLE=next
ARG VERSION
ENV MIX_ENV=${MIX_ENV}

# Validate required environment variables
RUN if [ -z "${VERSION}" ]; then echo "VERSION is unset" && exit 1; fi
RUN if [ -z "${BUNDLE}" ]; then echo "BUNDLE is unset" && exit 1; fi

# Frontend build steps (from build-frontend script)
RUN cd assets && \
    npm install && \
    npx -y -i browserslist@latest && \
    npx browserslist --update-db

# Production release steps (from build-release script)
RUN mix assets.setup && \
    mix assets.deploy && \
    MIX_ENV=prod mix release --overwrite --path "${VERSION}" && \
    chmod -R a+rX "${VERSION}"

# Diagnostics
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
      libssl-dev \
      libncurses-dev \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG APP_NAME=core
ARG VERSION

ENV HOME=/app \
    PORT=4000 \
    APP_NAME=core

# Copy the built release in
COPY --from=build_release /app/core/${VERSION} ./

# Prepare uploads dir
RUN mkdir -p /home/next/uploads

ENTRYPOINT ["/app/bin/core"]
CMD ["start"]
