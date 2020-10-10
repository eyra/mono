# Intro

This is primary documentation for the Link application.

# Development 

## Setup

1. Install Visual Studio Code
2. Checkout out the code locally
3. Open the folder with Visual Studio Code
4. Answer *yes* when it asks to "Reopen folder to develop in a container ..."

## Phoenix

The application is written in Elixir with use of the Phoenix web-framework. To
start your Phoenix server:

  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Learn more about Phoenix by visiting the [official website](https://www.phoenixframework.org/)

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

    git push gigalixir main:master

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

Enable branch protection on the `main` branch. This ensures that deployments
work (the deployment does not do a force push to Gigalixir).