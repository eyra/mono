# `Systems.BFF.Blocks`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L1)

The BFF blocks and pages, generated at compile time from the mica-bff spec.

# `check`

```elixir
@spec check([String.t() | nil], [map()]) :: :ok | {:error, String.t()}
```

`:ok` when `markup` holds for the blocks with `ids`, in page order, or
`{:error, reason}` for the first entry that doesn't: one whose `start` or `end`
is no block's id or an id two blocks have, one that ends before it starts, or one
that crosses an entry before it. Markup nests as in XML: two entries share no
block, or one covers all of the other. Two blocks with one id are fine as long as
no markup names that id.

# `page_params`

```elixir
@spec page_params(atom(), %{required(String.t()) =&gt; term()}) :: %{
  required(atom()) =&gt; term()
}
```

The params of `page` in `query`, a request's query parameters, by name and typed:
`page_params(:marketplace, %{"year" => "2025"})` is `%{year: 2025}`. One the page
doesn't declare, one that is empty and one that doesn't parse are left out, as if
absent: a stale link still opens the page.

# `pages`

```elixir
@spec pages() :: [
  %{name: atom(), path: String.t(), params: [%{name: atom(), type: atom()}]}
]
```

The pages the BFF serves, in spec order: each is a GET at its path that returns its view model, blocks and markup.

# `tree`

```elixir
@spec tree([String.t() | nil], [map()]) :: [
  {:block, String.t() | nil} | {:markup, map(), list()}
]
```

The nested tree a client renders for the blocks with `ids`, in page order, and
their `markup`: `{:block, id}` and `{:markup, entry, children}`. Entries over the
same stretch nest in list order, the first outermost. Like a client, it leaves out
an entry that `check/2` refuses, and the blocks it covers still show.

# `view_model`

```elixir
@spec view_model([struct()], [struct()]) :: %{required(String.t()) =&gt; [map()]}
```

The page as it goes on the wire, `%{"blocks" => [...], "markup" => [...]}`: the
blocks in page order and the markup beside them. Raises `ArgumentError` when the
markup is bad (`check/2`): the server never sends bad markup.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
