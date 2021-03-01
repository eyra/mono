all: sync install build

setup: sync install build

install: install_dependencies install_assets

install_dependencies:
	@echo "Installing dependencies"
	@mix deps.get

install_assets:
	@echo "Installing assets"
	@cd ./assets && npm install

build: compile_assets

compile_assets:
	@echo "Compiling assets"
	@cd ./assets && npm run deploy
	@mix phx.digest

sync: sync_repo sync_assets

sync_repo:
	@echo "Synching database migrations"
	@rsync -rupE --delete ../../../priv/repo/ priv/repo/

sync_assets:
	@echo "Synching global assets"
	@rsync -rupE --delete --exclude "node_modules/" ../../../assets/ assets/

run: sync
	@echo "Starting Phoenix server"
	@mix phx.server

gettext:
	@mix gettext.extract --merge

clean:
	@rm -rf assets
	@rm -rf priv/repo
	@rm -rf priv/static
	@rm -rf priv/cldr
	@rm -rf deps
	@rm -rf _build
