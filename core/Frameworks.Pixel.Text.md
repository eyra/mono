# `Frameworks.Pixel.Text`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/text.ex#L1)

Text components with various typography styles.

## Testing Convention
All text components accept an optional `testid` attribute for testing purposes:
```elixir
<Text.title1 testid="my-title">Content</Text.title1>
<Text.body testid="my-body">Content</Text.body>
```

The testid is rendered as `data-testid` on the outermost `<div>` wrapper of each text component.

# `body`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `body_large`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `body_medium`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `body_small`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `bullet`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `image` (`:string`) (required)
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `caption`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey2"`.
* `text_alignment` (`:string`) - Defaults to `"text-center"`.
* `padding` (`:string`) - Defaults to `"pl-4 pr-4"`.
* `margin` (`:string`) - Defaults to `"mb-6"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `footnote`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey2"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `form_field_label`

## Attributes

* `id` (`:any`) (required)
* `color` (`:string`) - Defaults to `"text-grey1"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `hint`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey2"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `intro`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `margin` (`:string`) - Defaults to `"lg:mb-9"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `label`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `sub_head`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey2"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `table_head`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `table_row`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title0`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title1`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `margin` (`:string`) - Defaults to `"mb-7 lg:mb-9"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title2`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `margin` (`:string`) - Defaults to `"mb-5 md:mb-6 lg:mb-8"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title3`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `margin` (`:string`) - Defaults to `"mb-5"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title4`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title5`

## Attributes

* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-center"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title6`

## Attributes

* `margin` (`:string`) - Defaults to `"mb-2"`.
* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

# `title7`

## Attributes

* `margin` (`:string`) - Defaults to `""`.
* `color` (`:string`) - Defaults to `"text-grey1"`.
* `align` (`:string`) - Defaults to `"text-left"`.
* `testid` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block` (required)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
