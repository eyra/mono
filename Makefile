BUNDLES=$(wildcard apps/bundles/*)
FRAMEWORKS=$(wildcard apps/frameworks/*)

all: test format compile credo deps

prepare: test format compile credo

test: ${BUNDLES:%=test/%} ${FRAMEWORKS:%=test/%} test/apps/core
test/%:
	cd $* && mix test

format: ${BUNDLES:%=format/%} ${FRAMEWORKS:%=format/%} format/apps/core
format/%:
	cd $* && mix format

credo: ${BUNDLES:%=credo/%} ${FRAMEWORKS:%=credo/%} credo/apps/core
credo/%:
	cd $* && mix credo

compile: ${BUNDLES:%=credo/%}
compile/%:
	cd $* && mix compile --force --warnings-as-errors

deps: ${BUNDLES:%=deps/%} ${FRAMEWORKS:%=deps/%} deps/apps/core
deps/%:
	cd $* && mix deps
