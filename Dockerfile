FROM debian:12

WORKDIR /root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    unzip \
    automake \
    autoconf \
    libssl-dev \
    libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2 \
    && echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc \
    && echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

RUN echo "export PATH=\"$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH\"" >> ~/.bashrc

RUN bash -c "source ~/.bashrc && \
    asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git"


COPY .tool-versions /root/.tool-versions

RUN bash -c "source ~/.bashrc && asdf install"

RUN echo "source ~/.bashrc" >> ~/.profile

RUN bash -c "source ~/.bashrc && mix local.hex --force && mix local.rebar --force"

COPY ./core /app/core
WORKDIR /app/core

RUN bash -c "source ~/.bashrc && mix deps.get"

# CMD ["/bin/bash", "-c", "source ~/.bashrc && mix run"]
CMD ["tail", "-f", "/dev/null"]


