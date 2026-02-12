# Eyra Mono

Codebase used by the Next platform, which is also available for self hosting (see [bundles](https://github.com/eyra/mono#bundles)).

## Projects

* Core
* Banking Proxy

## Core

Project implementing a SaaS platform based on interlinked modules called Systems. These Systems are composed into Bundles to form specific deployments. Deployments use config to expose a set of features (web pages) to the public.

### Systems (shortlist)

* Banking
* Bookkeeping
* Budget
* Advert
* Assignment
* Lab
* Questionnaire
* Pool
* ..

### Bundles

* Next

Primary bundle with all features available. Next is configured and hosted by Eyra.

* Self

Customizable bundle that can be used to run Core on one of your own servers.
See [SELFHOSTING.md](SELFHOSTING.md) for detailed instructions.


## Testing

### Unit Tests
```bash
cd core
mix test --warnings-as-errors
```

### E2E Tests (Playwright)
Browser-based end-to-end tests for user flows.
```bash
cd core/test/e2e
npm install
npx playwright test
```
See [core/test/e2e/README.md](core/test/e2e/README.md) for configuration options.

### Load Tests (Artillery)
Performance and stress testing for the data donation API.
```bash
cd core/test/load
npm run setup  # Install deps + generate test data files
npm run test:quick  # Quick sanity check
```
See [core/test/load/README.md](core/test/load/README.md) for all test configurations.

## Banking Proxy

Project implementing a proxy server used in Banking (core/systems/banking). It allows for a limited and secure interaction with a banking account.


## Using TLS between app and database
TLS peer verification is possible between the elixir app and the postgres database. By default this is enabled. To disable it, set `DB_TLS_VERIFY=none` in the docker compose file.
To make sure everything is set up correctly, you can generate the certs using the following commands:
```bash
./postgres_ssl/generate.sh
```
This command will generate the certs in the `postgres_ssl` directory. The certs are generated using the `openssl` command. The custom docker file for the postgres image will copy the certs to the correct location in the image.