#!/bin/sh -e

bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-previous-release-team-keyring'

asdf plugin-add erlang || true
asdf plugin-add elixir || true
asdf plugin-add nodejs || true
asdf install

cd assets
asdf exec npm install
cd ..

asdf exec mix deps.get

echo "All done. Reload your shell to enable the new commands."
