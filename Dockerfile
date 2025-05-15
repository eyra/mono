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

COPY ./core /app/core
WORKDIR /app/core


# ======================
# Dev Stage
# ======================
FROM builder AS dev

RUN mix deps.get

CMD ["mix","run"]