# Eyra Mono

Primary collection of Eyra projects

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

Primary bundle with all features available. Next is configured and maintained by Eyra and hosted on: https://eyra.co

* Self

Customizable bundle that can be used to run Core on one of your own servers.
See [SELFHOSTING.md](SELFHOSTING.md) for detailed instructions.


## Banking Proxy

Project implementing a proxy server used in Banking (core/systems/banking). It allows for a limited and secure interaction with a banking account.
