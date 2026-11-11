# `Frameworks.Pixel.Button`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/button.ex#L1)

A colored button with white text.

# `action`

## Attributes

* `type` (`:atom`) (required)
* `full_width` (`:boolean`) - Defaults to `false`.
## Slots

* `inner_block` (required)

# `back`

## Attributes

* `path` (`:string`) (required)
* `label` (`:string`) (required)
* `icon` (`:string`) - Defaults to `"/images/back.svg"`.

# `delete`

## Attributes

* `path` (`:string`) (required)
* `label` (`:string`) (required)

# `dynamic`

## Attributes

* `action` (`:map`) (required)
* `face` (`:map`) (required)
* `enabled?` (`:boolean`) - Defaults to `true`.
* `full_width` (`:boolean`) - Defaults to `false`.
* `testid` (`:string`) - Defaults to `nil`.

# `dynamic_bar`

## Attributes

* `buttons` (`:list`) (required)

# `face`

## Attributes

* `type` (`:atom`) (required)
* `icon` (`:any`) - Defaults to `nil`.

# `primary`

## Attributes

* `to` (`:string`) (required)
* `label` (`:string`) (required)
* `bg_color` (`:string`) - Defaults to `"bg-primary"`.

# `primary_icon`

## Attributes

* `to` (`:string`) (required)
* `label` (`:string`) (required)
* `icon` (`:string`) (required)
* `bg_color` (`:string`) (required)

# `primary_live_view`

## Attributes

* `label` (`:string`) (required)
* `event` (`:string`) (required)
* `width` (`:string`) - Defaults to `"pl-4 pr-4"`.
* `target` (`:any`) - Defaults to `nil`.
* `testid` (`:string`) - Defaults to `nil`.

# `primary_wide`

## Attributes

* `to` (`:string`) (required)
* `label` (`:string`) (required)
* `bg_color` (`:string`) (required)

# `secondary_live_view`

## Attributes

* `label` (`:string`) (required)
* `event` (`:string`) (required)
* `color` (`:string`) - Defaults to `"text-delete"`.
* `width` (`:string`) - Defaults to `"pl-4 pr-4"`.
* `target` (`:any`)

# `submit`

## Attributes

* `label` (`:string`) (required)
* `bg_color` (`:string`) - Defaults to `"bg-primary"`.
* `target` (`:string`) - Defaults to `""`.

# `submit_wide`

## Attributes

* `label` (`:string`) (required)
* `bg_color` (`:string`) - Defaults to `"bg-primary"`.
* `testid` (`:string`) - Defaults to `nil`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
