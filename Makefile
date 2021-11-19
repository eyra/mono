BUNDLES=$(wildcard core/bundles/*)
MIX_PROJECTS=core

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
dialyzer: FORCE
	cd core && mix dialyzer --force-check

.PHONY: test
test: ${MIX_PROJECTS:%=test/%}
test/%: FORCE
	cd $* && mix test

.PHONY: format
format: ${MIX_PROJECTS:%=format/%}
format/%: FORCE
	cd $* && mix format

.PHONY: credo
credo: ${MIX_PROJECTS:%=credo/%}
credo/%: FORCE
	cd $* && mix credo

.PHONY: compile
compile: ${MIX_PROJECTS:%=%/_build}
%/_build: FORCE
	cd $* && mix compile --force --warnings-as-errors

.PHONY: deps
deps: ${MIX_PROJECTS:%=%/deps}
%/deps: FORCE
	cd $* && mix deps.get

.PHONY: docs
docs: ${MIX_PROJECTS:%=%/doc}
%/doc:
	mkdir -p doc
	cd $* && mix docs
	cp -R $*/doc/ doc/`basename $*`

.PHONY: FORCE