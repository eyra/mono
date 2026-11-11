# `Frameworks.Pixel.ModalView`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/modal_view.ex#L1)

# `background`

## Attributes

* `visible` (`:boolean`) - Defaults to `false`.
## Slots

* `inner_block` (required)

# `compact`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)

# `content`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)
* `toolbar_buttons` (`:list`) - Defaults to `[]`.

# `dynamic`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) - Defaults to `nil`.
* `toolbar_buttons` (`:list`) - Defaults to `[]`.

# `forward_toolbar_action`

Forwards a toolbar action to the target LiveView process.
Source is a tuple {pid, element_id} from LiveNest.Event.

# `frame`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)
* `toolbar_buttons` (`:list`) - Defaults to `[]`.

# `full`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)
* `toolbar_buttons` (`:list`) - Defaults to `[]`.

# `max`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)

# `modal_id`

# `page`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)
* `toolbar_buttons` (`:list`) - Defaults to `[]`.

# `resolve_aspects`

Resolves modal aspects from style (legacy), preset, or explicit options.
Returns a keyword list of resolved aspects.

# `sheet`

## Attributes

* `socket` (`:map`) (required)
* `modal` (`:map`) (required)

# `title2`

## Attributes

* `modal` (`:map`) (required)
* `centered?` (`:boolean`) - Defaults to `false`.

# `title3`

## Attributes

* `modal` (`:map`) (required)

# `update_modal_buttons`

Updates modal toolbar buttons in socket assigns.
Called when embedded view publishes :update_modal_buttons event.
Stores source for event forwarding and buttons for the Toolbar LiveComponent.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
