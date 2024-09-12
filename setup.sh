#!/bin/sh -e

asdf plugin-add erlang || true
asdf plugin-add elixir || true
asdf plugin-add nodejs || true

asdf install

cd ./core/assets
asdf exec npm install
cd ..

asdf exec mix deps.get

echo "All done. Reload your shell to enable the new commands."
