#!/bin/sh -e

# Temp hack for https://bugs.erlang.org/browse/ERL-1407
export MACOSX_DEPLOYMENT_TARGET=10.0

bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-previous-release-team-keyring'

asdf plugin-add erlang || true
asdf plugin-add elixir || true
asdf plugin-add postgres || true
asdf plugin-add nodejs || true
asdf install

cd assets
asdf exec npm install
cd ..

asdf exec mix deps.get

if [ ! -d db ]
then
    asdf exec initdb --username=link db
    asdf exec pg_ctl -D db start
    asdf exec createdb --owner=link --username=link link_dev
    asdf exec pg_ctl -D db stop
fi

echo "All done. Reload your shell to enable the new commands."