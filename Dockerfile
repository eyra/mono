# Gebruik Debian 12 als basisafbeelding
FROM debian:12

# Zet de werkdirectory in de container
WORKDIR /root

# Installeer vereiste afhankelijkheden en configureer asdf in één stap
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

# Installeer asdf versiebeheer tool
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2 \
    && echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc \
    && echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc

# Stel omgevingsvariabelen in voor asdf en installeer Erlang en Elixir plugins
RUN echo "export PATH=\"$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH\"" >> ~/.bashrc

# Laad asdf en voeg de plugins toe voor Erlang en Elixir
RUN bash -c "source ~/.bashrc && \
    asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git"


# Installeer de juiste versie van Erlang en Elixir vanuit .tool-versions (indien beschikbaar)
# Als je een specifieke versie van Erlang en Elixir wilt installeren, kun je dit hier doen
COPY .tool-versions /root/.tool-versions

# Installeer Erlang en Elixir
RUN bash -c "source ~/.bashrc && asdf install"

# Zorg ervoor dat het systeem toegang heeft tot de versies
RUN echo "source ~/.bashrc" >> ~/.profile

# Installeer mix en zorg ervoor dat het beschikbaar is
RUN bash -c "source ~/.bashrc && mix local.hex --force && mix local.rebar --force"

WORKDIR /app/core

# make sure to use the bash shell when running mix run:
CMD ["/bin/bash", "-c", "source ~/.bashrc && mix run"]


