BUNDLES=$(wildcard apps/bundles/*)
FRAMEWORKS=$(wildcard apps/frameworks/*)

all: test format compile credo deps

setup: install_assets

install_assets:
	@echo "Installing assets"
	@cd ./assets && npm install

prepare: test format compile credo

dialyzer: ${BUNDLES:%=dialyzer/%} ${FRAMEWORKS:%=dialyzer/%} dialyzer/apps/core
dialyzer/%:
	cd $* && mix dialyzer

#test: ${BUNDLES:%=test/%} ${FRAMEWORKS:%=test/%} test/apps/core
test: ${FRAMEWORKS:%=test/%} test/apps/core
test/%:
	cd $* && mix test

format: ${BUNDLES:%=format/%} ${FRAMEWORKS:%=format/%} format/apps/core
format/%:
	cd $* && mix format

credo: ${BUNDLES:%=credo/%} ${FRAMEWORKS:%=credo/%} credo/apps/core
credo/%:
	cd $* && mix credo

compile: ${BUNDLES:%=compile/%}
compile/%:
	cd $* && mix compile --force --warnings-as-errors

deps: ${BUNDLES:%=deps/%} ${FRAMEWORKS:%=deps/%} deps/apps/core
deps/%:
	cd $* && mix deps.get
