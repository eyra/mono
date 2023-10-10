all: install deploy gettext build

setup: install

install: install_dependencies install_assets

deploy: deploy_assets

install_dependencies:
	@echo "Installing dependencies"
	@mix deps.get

install_assets:
	@echo "Installing assets"
	@cd ./assets && npm install

deploy_assets:
	@echo "Deploying assets"
	@cd ./assets && npm run deploy

gettext:
	@mix gettext.extract --merge

build: build-digest build-app

build-assets:
	@cd .assets && npm run build

build-digest:
	@mix phx.digest

build-app:
	@mix compile

run:
	@echo "Starting Phoenix server"
	@mix phx.server

clean:
	@rm -rf deps
	@rm -rf _build
	@rm -rf priv/cldr
