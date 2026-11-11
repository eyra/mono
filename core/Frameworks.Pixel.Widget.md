# `Frameworks.Pixel.Widget`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/widget.ex#L1)

# `number`

## Attributes

* `integer` (`:integer`) (required)
* `label` (`:string`) (required)
* `color` (`:atom`) - Defaults to `:primary`.
* `target` (`:any`) - Defaults to `nil`.
* `target_direction` (`:atom`) - Defaults to `nil`.

# `progress`

## Attributes

* `label` (`:string`) (required)
* `target_amount` (`:integer`) (required)
* `done_amount` (`:integer`) (required)
* `pending_amount` (`:integer`) (required)
* `done_label` (`:string`) (required)
* `pending_label` (`:string`) (required)
* `target_label` (`:string`) (required)

# `value_distribution`

## Attributes

* `label` (`:string`) (required)
* `scale` (`:integer`) (required)
* `values` (`:list`) (required)

# `value_distribution_bar`

## Attributes

* `value_count` (`:integer`) (required)
* `height` (`:integer`) (required)
* `range_label` (`:string`) (required)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
