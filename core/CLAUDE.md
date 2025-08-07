# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Dependencies
- `mix setup` - Full project setup (deps, database, assets)
- `mix deps.get` - Install Elixir dependencies
- `cd assets && npm install` - Install frontend dependencies

### Database
- `mix ecto.setup` - Create and migrate database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database
- `mix ecto.reset.link` - Reset with link bundle seeds

### Testing
- `mix test` - Run all tests
- `mix test test/path/to/specific_test.exs` - Run a specific test file
- `mix test --cover` - Run tests with coverage

### Development Server
- `mix phx.server` or `mix run` - Start development server on port 4000

### Code Quality
- `mix credo` - Run static code analysis
- `mix dialyzer` - Run type checking
- `mix format` - Format Elixir code
- `./assets/node_modules/.bin/prettier --check ./assets/js` - Check JS formatting
- `./assets/node_modules/.bin/prettier -w ./assets/js` - Format JS code

### Assets
- `mix assets.build` - Build frontend assets
- `mix assets.deploy` - Build and minify assets for production

### Internationalization
- `mix i18n` - Extract translation strings

## Architecture Overview

This is an Elixir Phoenix LiveView application using a **Systems-based architecture** where functionality is organized into autonomous systems rather than traditional MVC layers.

### Core Architecture Components

#### Systems (`/systems/`)
- **Autonomous modules** containing complete functionality (models, views, logic, routes)
- Each system has optional **features** indicated by files starting with underscore:
  - `_public.ex` - Public API for other systems
  - `_private.ex` - Internal implementation details
  - `_queries.ex` - Database queries and data access
  - `_presenter.ex` - View model presentation logic
  - `_routes.ex` - Phoenix routing for web endpoints
  - `_switch.ex` - Signal routing and event handling
  - `_assembly.ex` - System component assembly
  - `_plug.ex` - HTTP request processing

#### Frameworks (`/frameworks/`)
- **Concept** - Core system abstractions and behaviors
- **Fabric** - LiveView and component utilities (deprecated, being replaced by LiveNest)
- **GreenLight** - Authorization and permissions system
- **Pixel** - UI component library (buttons, forms, cards, etc.)
- **Signal** - Inter-system communication bus
- **Utility** - Common helper modules

#### LiveNest Framework
- **LiveNest** - Modern replacement for Fabric framework
- Internally created Elixir dependency for LiveView utilities
- Designed as open-source framework for broader community use
- Handles LiveView component composition and state management

#### File Naming Conventions
- `*_model.ex` - Ecto schemas and data models
- `*_form.ex` - Form components for data input
- `*_view.ex` - Display components
- `*_page.ex` - LiveView pages
- `*_controller.ex` - Phoenix controllers

### Key Systems
- **Account** - User management, authentication, profiles
- **Assignment** - Research assignments and workflows
- **Project** - Project management and organization
- **Storage** - File storage backends (builtin, AWS, Azure, Yoda)
- **Graphite** - Benchmarking and leaderboards
- **Pool** - Participant pools for studies
- **Crew** - Task management and collaboration
- **Budget** - Financial management and rewards

#### Next Generation Knowledge Systems (Human-AI Collaboration → Global Knowledge Democracy)
These systems form a sophisticated **human-AI collaboration platform** that evolves into a **global knowledge democracy**:

- **Annotation** - Human-readable knowledge layer → Open global knowledge platform
  - **Infinite Flexibility**: Annotations can connect to knowledge graph in indefinite ways
  - **Recipe Organization**: Structured patterns define meaningful knowledge arrangements
  - **Global Commitment**: Natural language knowledge committed to immutable blockchain
  - **Third-Party APIs**: Open access for external developers to build knowledge applications

- **Ontology** - Formal knowledge layer → Open semantic infrastructure
  - Stores AI-formalized concepts, predicates, and logical structures
  - Continuously evolves through AI processing of human annotations
  - **Global Truth Infrastructure**: Immutable blockchain for consensus-validated formal knowledge
  - **Open Semantic APIs**: Third-party access to formal knowledge for innovation ecosystem

- **Onyx** - Human-AI collaboration interface → Public knowledge browser
  - Visual platform for validating AI-synthesized knowledge
  - Real-time visualization of knowledge formalization process
  - **Future**: Tools for citizens to "surf" the state-of-art of science
  - **Democratic Science**: Transform how society accesses scientific knowledge

- **Zircon** - Foundational knowledge population tool → Universal research platform
  - **Primary Knowledge Seeder**: First tool to populate the Annotation/Ontology layers
  - **Universal Research Tool**: Systematic review needed by every researcher
  - **Knowledge Graph Builder**: Transforms literature reviews into formal knowledge
  - **Future**: Foundation for additional research tools populating global knowledge base

### Signal Architecture
Systems communicate through the **Signal framework** for loose coupling:
- Child systems communicate with parents only through Signal
- Direct function calls between systems are discouraged
- Signals are dispatched for state changes and events
- Each system can have a `_switch.ex` to handle incoming signals

### Authorization
Uses **GreenLight** framework with hierarchical permissions:
- Tree-based authorization nodes
- Role assignments at different levels
- Permission inheritance through the tree structure

### Database
- PostgreSQL with Ecto ORM
- Migrations in `/priv/repo/migrations/`
- Models use `use Core, :model` for common functionality

### Frontend
- Phoenix LiveView for reactive UI
- Tailwind CSS for styling
- Custom JavaScript hooks in `/assets/js/`
- Component library in `frameworks/pixel/components/`

### Testing
- Uses ExUnit with custom test cases:
  - `Core.DataCase` for database tests
  - `CoreWeb.ConnCase` for controller/LiveView tests
- Factory functions in `Core.Factories` and system-specific factories
- Mocking with Mox for external dependencies
- Signal testing with `Frameworks.Signal.TestHelper`

## Development Guidelines

### Elixir Style Rules
- **No alias grouping** - Each alias on separate line
- Prefer single system alias: `alias Systems.Account` then use `Account.Model`
- Follow existing naming patterns and file structures

### Testing Patterns
- Use associations over foreign keys in tests
- Always preload associations before asserting
- Use factory functions for test data creation
- Test both positive and negative cases

### Signal Usage
- Use Signal for inter-system communication
- Document all signals a system sends/receives
- Implement proper error handling for signals
- Test signal handlers in isolation

### System Development
- Keep systems autonomous and loosely coupled
- Use appropriate system features (`_public.ex`, `_queries.ex`, etc.)
- Follow existing patterns for models, forms, views, and pages
- Implement proper authorization using GreenLight

## Bundle System
The application supports different "bundles" (configurations):
- Bundle selection via `.bundle.ex` file in root
- Bundle-specific config in `/bundles/{bundle}/config/`
- Current bundles: `next`, `self`