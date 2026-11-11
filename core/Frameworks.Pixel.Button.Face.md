# `Frameworks.Pixel.Button.Face`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/button_face.ex#L1)

The look of a button, inside a `Frameworks.Pixel.Button.Action`. Every face but
the menu faces renders Prism's button (`Frameworks.Pixel.button/1`) as a
`<div>`, since the action is the clickable element.

`bg_color`, `text_color`, `border_color` and `font` take Tailwind classes that
override Prism's look; without them a face has its Prism variant's colors and
typography.

Prism's button is inline (`inline-flex`); the icon, label and `*_icon` faces take
a line of their own (`flex`), so no line box adds height around them.

# `icon`

## Attributes

* `icon` (`:atom`) (required)
* `color` (`:string`) - Defaults to `nil`.
* `alt` (`:string`) - Defaults to `""`.
* `size` (`:string`) - Defaults to `nil`.

# `icon_name`

# `label`

## Attributes

* `label` (`:string`) (required)
* `wrap` (`:boolean`) - Defaults to `false`.
* `text_color` (`:string`) - Defaults to `nil`.
* `font` (`:string`) - Defaults to `nil`.

# `label_icon`

## Attributes

* `label` (`:string`) (required)
* `icon` (`:atom`) (required)
* `color` (`:string`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `nil`.
* `height` (`:string`) - Defaults to `"h-10"`.

# `link`

## Attributes

* `text` (`:string`) (required)
* `font` (`:string`) - Defaults to `nil`.

# `menu_home`

## Attributes

* `icon` (`:atom`) (required)
* `size` (`:atom`) - Defaults to `:wide`.

# `menu_item`

## Attributes

* `title` (`:string`) (required)
* `active?` (`:boolean`) - Defaults to `false`.
* `counter` (`:integer`) (required)
* `icon` (`:map`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `"text-grey1"`.

# `plain`

## Attributes

* `label` (`:string`) (required)
* `text_color` (`:string`) - Defaults to `nil`.

# `plain_icon`

## Attributes

* `label` (`:string`) (required)
* `icon` (`:atom`) - Defaults to `:forward`.
* `icon_align` (`:atom`) - Defaults to `:right`.
* `text_color` (`:string`) - Defaults to `nil`.

# `primary`

## Attributes

* `label` (`:string`) (required)
* `bg_color` (`:string`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `nil`.
* `loading` (`:boolean`) - Defaults to `false`.
* `full_width` (`:boolean`) - Defaults to `false`.

# `primary_icon`

## Attributes

* `label` (`:string`) (required)
* `icon` (`:atom`) (required)
* `bg_color` (`:string`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `nil`.

# `secondary`

## Attributes

* `label` (`:string`) (required)
* `border_color` (`:string`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `nil`.
* `loading` (`:boolean`) - Defaults to `false`.

# `secondary_icon`

## Attributes

* `label` (`:string`) (required)
* `icon` (`:atom`) (required)
* `border_color` (`:string`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `nil`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
