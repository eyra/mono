# Development Setup

## Setup

For Windows; first install [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10) and the [Windows Terminal](https://docs.microsoft.com/nl-nl/windows/terminal/). Run all steps in the WSl2 environment.

For OS X; install GnuPG, `brew install gnupg`.

1. Install Visual Studio Code (or another editor)
2. Checkout out the code locally
3. [Install ASDF](https://asdf-vm.com/#/core-manage-asdf?id=install)
4. Go to the checkout folder and run: `./setup.sh`

This will setup all required dependencies.

## Pre-commit

The project has several code quality tools in place. These can be  automatically executed on commit & push. Install [pre-commit](https://pre-commit.com/#install) to enable this. Then run:

    pre-commit install

## Database

Get PostgreSQL:

- [OS X](https://postgresapp.com))
- [Windows](https://www.postgresql.org/download/windows/)

Now run the migrations with:

    mix ecto.migrate

## Phoenix

The application is written in Elixir with use of the Phoenix web-framework. To
start your Phoenix server:

  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Learn more about Phoenix by visiting the [official website](https://www.phoenixframework.org/)

## i18n

This project makes use of `Gettext` and `Cldr` for internationalization. The
`PO` files can be found at `priv/gettext/*/LC_MESSAGES/*.po`. To extract new
translation strings or to compile the `PO` files run:

    mix i18n

## Linting & Style

Several linting tools are available to ensure code quality. They are:

- [Credo](https://github.com/rrrene/credo) (`mix credo`)
- [mix format](https://hexdocs.pm/mix/master/Mix.Tasks.Format.html) (`mix format`)

# Deployment

## Gigalixir

Gigalixir is used for deployment. To be able to the run the commands open a
terminal (within Visual Studio Code). Further explaination on how to login etc.
is in [the documentation for Gigalixir](https://gigalixir.readthedocs.io/en/latest/getting-started-guide.html#log-in).

To manually deploy a version run:

    git push gigalixir master

## Continous Deployment

GitHub Actions is used for continuous integration and deployment. It requires
the following secrets to be confirured on the repository level (in the settings
screen).

    GIGALIXIR_USERNAME
    GIGALIXIR_PASSWORD
    SSH_PRIVATE_KEY

The SSH key is used to enable automatic database migrations. To create a
deployment key run:

    ssh-keygen -t rsa -b 4096 -N "" -f deployment.key

This creates two files `deployment.key` and `deployment.key.pub`. Run `code
deployment.key` to open the private key and paste it's contents into a the
GitHub secret called `SSH_PRIVATE_KEY`.

Run the following command to enable the key in Gigalixir.

    gigalixir account:ssh_keys:add "$(cat deployment.key.pub)"

## GitHub branch protections

Enable branch protection on the `master` branch. This ensures that deployments
work (the deployment does not do a force push to Gigalixir).

## Authorization

The application has a deeply integrated authorization system. It is described in
detail in `guides/authorization.md`. To list the permission that and their role
assignments run:

    mix grlt.perms

## Documentation

There are guides and code has comments to explain the functionality. The documentation can be converted into HTML or Epub with ExDoc. The command to generate the documentation is:

    mix docs
