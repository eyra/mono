# `Frameworks.Pixel.List`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/list.ex#L1)

A generic list LiveComponent with optional search + pagination.

Consumers pass in the full `rows` list and a `:row` slot that renders
one row. Adding a `haystack_fn` enables search; adding `page_size`
enables pagination.

Row-level actions (e.g. `phx-target={@myself}`) resolve to the CONSUMER
LC because slot content is compiled in the consumer's rendering
context — so an "action" button in a row fires against the consumer,
not this wrapper.

# `add_child`

# `async`

# `auth_module`

# `compose`

# `compose_child`

# `compose_element`

# `handle_info`

# `print_auth_roles`

# `render`

## Attributes

* `id` (`:string`) (required)
* `rows` (`:list`) (required)
* `page_size` (`:integer`) - Defaults to `nil`.
* `haystack_fn` (`:any`) - Defaults to `nil`.
* `placeholder` (`:string`) - Defaults to `"Search"`.
* `no_match` (`:string`) - Defaults to `""`.
* `justify` (`:atom`) - Defaults to `:start`.
* `item_height` (`:string`) - Defaults to `"54px"`.
* `stretch` (`:boolean`) - Defaults to `false`.
## Slots

* `row` (required)
* `empty`

# `reset_fabric`

# `update_child`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
