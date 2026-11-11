# `Next.Frameworks.Concept.ScreeningAgent`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/zircon/screening/screening_agent.ex#L1)

# `annotation`

```elixir
@type annotation() :: Next.Systems.Annotation.Model.t()
```

# `concept`

```elixir
@type concept() :: Next.Systems.Ontology.ConceptModel.t()
```

# `criterion`

```elixir
@type criterion() :: annotation()
```

# `criterion_id`

```elixir
@type criterion_id() :: String.t()
```

# `decision`

```elixir
@type decision() :: :include | :exclude | :undecided
```

# `internal_id`

```elixir
@type internal_id() :: String.t()
```

# `label`

```elixir
@type label() :: annotation()
```

# `paper`

```elixir
@type paper() :: Next.Systems.Paper.Model.t()
```

# `paper_id`

```elixir
@type paper_id() :: String.t()
```

# `reason`

```elixir
@type reason() :: String.t()
```

# `review_attrs`

```elixir
@type review_attrs() :: map()
```

# `session_id`

```elixir
@type session_id() :: String.t()
```

# `state`

```elixir
@type state() :: map()
```

# `next_paper`

```elixir
@callback next_paper(state()) :: {:ok, {state(), paper_id()}} | {:error, reason()}
```

# `start`

```elixir
@callback start(session_id(), papers :: [paper()], criteria :: [criterion()]) ::
  {:ok, state()} | {:error, reason()}
```

# `update_paper`

```elixir
@callback update_paper(state(), paper_id(), criterion_id(), label()) ::
  {:ok, state()} | {:error, reason()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
