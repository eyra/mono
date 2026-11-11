# `Frameworks.Pixel.Button.Action`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/button_action.ex#L1)

Button action components that handle different interaction types.

## Testing Convention
All action functions accept an optional `testid` attribute that is applied
to the outermost interactive element (button, anchor, div, etc.) as
`data-testid`. This ensures:
- Test selectors target the actual clickable element
- Disabled states still have testids on their wrapper
- Each action type correctly applies testids to its specific HTML semantics

When adding new action types, always include:
```elixir
attr(:testid, :string, default: nil)
```
And apply it to the outermost interactive element:
```elixir
<a ... data-testid={@testid}>
```

# `fake`

## Attributes

* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `http`

## Attributes

* `to` (`:string`) (required)
* `method` (`:string`) (required)
* `target` (`:string`) - Defaults to `"_self"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `http_delete`

## Attributes

* `to` (`:string`) (required)
* `target` (`:string`)
## Slots

* `inner_block` (required)

# `http_download`

## Attributes

* `to` (`:string`) (required)
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `http_get`

## Attributes

* `to` (`:string`) (required)
* `target` (`:string`) - Defaults to `"_self"`.
* `phx_event` (`:string`) - Defaults to `nil`.
* `phx_target` (`:string`) - Defaults to `nil`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `http_new`

## Attributes

* `to` (`:string`) (required)
* `target` (`:string`)
## Slots

* `inner_block` (required)

# `http_post`

## Attributes

* `to` (`:string`) (required)
* `target` (`:string`)
## Slots

* `inner_block` (required)

# `label`

## Attributes

* `field` (`:string`) (required)
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `phoenix_js`

## Attributes

* `js` (`:any`) (required)
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `redirect`

## Attributes

* `to` (`:string`) (required)
* `replace` (`:boolean`) - Defaults to `false`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `send`

## Attributes

* `id` (`:string`) - Defaults to `"?"`.
* `event` (`:string`) (required)
* `item` (`:string`) - Defaults to `""`.
* `target` (`:string`) - Defaults to `""`.
* `enabled?` (`:boolean`) - Defaults to `true`.
* `debounce` (`:string`) - Defaults to `nil`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `submit`

## Attributes

* `form_id` (`:string`) - Defaults to `nil`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `toggle`

## Attributes

* `id` (`:string`) (required)
* `target` (`:string`) (required)
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
