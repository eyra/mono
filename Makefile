BUNDLES=$(wildcard core/bundles/*)
FRAMEWORKS=$(wildcard frameworks/*)
MIX_PROJECTS=${FRAMEWORKS} core

.PHONY: all
all: test format compile credo deps

.PHONY: setup
setup: install_assets

.PHONY: install_assets
install_assets:
	@echo "Installing assets"
	@cd ./core/assets && npm install

.PHONY: prepare
prepare: test format compile credo

.PHONY: dialyzer
dialyzer:
	cd core && mix dialyzer --force-check

.PHONY: test
test: ${MIX_PROJECTS:%=test/%}
test/%:
	cd $* && mix test

.PHONY: format
format: ${MIX_PROJECTS:%=format/%}
format/%:
	cd $* && mix format

.PHONY: credo
credo: ${MIX_PROJECTS:%=credo/%}
credo/%:
	cd $* && mix credo

.PHONY: compile
compile: ${MIX_PROJECTS:%=%/_build}
%/_build:
	cd $* && mix compile --force --warnings-as-errors

.PHONY: deps
deps: ${MIX_PROJECTS:%=%/deps}
%/deps:
	cd $* && mix deps.get

.PHONY: docs
docs: ${MIX_PROJECTS:%=%/doc}
%/doc:
	mkdir -p doc
	cd $* && mix docs
	cp -R $*/doc/ doc/`basename $*`
