all: install gettext

setup: install

install: install_dependencies

install_dependencies:
	@echo "Installing dependencies"
	@mix deps.get

gettext:
	@mix gettext.extract --merge

clean:
	@rm -rf deps
	@rm -rf _build
