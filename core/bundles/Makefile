all: install build

setup: install build-digest

install: install_dependencies deploy_assets

install_dependencies:
	@echo "Installing dependencies"
	@mix deps.get

deploy_assets:
	@echo "Deploying assets"
	@cd ./assets && npm run deploy

build: build-digest build-digest

build-digest:
	@mix phx.digest

build-app:
	@mix compile

run:
	@echo "Starting Phoenix server"
	@mix phx.server

gettext:
	@mix gettext.extract --merge

clean:
	@rm -rf priv/cldr
	@rm -rf deps
	@rm -rf _build
