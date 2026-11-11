# `Frameworks.Pixel.Card`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/card.ex#L1)

The Unique Selling Point Card highlights a reason for taking an action.

# `button`

## Attributes

* `title` (`:string`) (required)
* `image` (`:string`) (required)
* `event` (`:string`) (required)

# `highlight`

## Attributes

* `title` (`:string`) (required)
* `text` (`:string`) (required)

# `label`

## Attributes

* `text` (`:string`) (required)
* `type` (`:atom`) - Defaults to `:primary`.

# `normal`

## Attributes

* `bg_color` (`:string`) - Defaults to `"bg-grey6"`.
* `size` (`:string`) - Defaults to `"h-full"`.
## Slots

* `inner_block` (required)
* `image`
* `title` (required)

# `primary_cta`

## Attributes

* `title` (`:string`) (required)
* `button_label` (`:string`) (required)
* `to` (`:string`) (required)
* `button_bg_color` (`:string`) - Defaults to `"bg-white"`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
