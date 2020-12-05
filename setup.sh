#!/bin/sh -e

asdf plugin-add erlang
asdf plugin-add elixir
asdf plugin-add postgres
asdf plugin-add nodejs
asdf plugin-add python
asdf install

cd assets
npm install
cd ..

mix deps.get

if [ ! -d db ]
then
    initdb --username=link db
    pg_ctl -D db start
    createdb --owner=link --username=link link_dev 
    pg_ctl -D db stop
fi