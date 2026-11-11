# `Frameworks.Pixel.ClickableCard`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/clickable_card.ex#L1)

The Unique Selling Point Card highlights a reason for taking an action.

# `action_button`

## Attributes

* `card_id` (`:any`) (required)
* `button` (`:map`) (required)
* `index` (`:integer`) (required)
* `position` (`:atom`) (required)

# `clickable_card`

## Attributes

* `id` (`:integer`) (required)
* `bg_color` (`:string`) - Defaults to `"grey6"`.
* `size` (`:string`) - Defaults to `"h-full"`.
* `left_actions` (`:list`) - Defaults to `[]`.
* `right_actions` (`:list`) - Defaults to `[]`.
* `target` (`:any`) - Defaults to `""`.
## Slots

* `inner_block` (required)
* `top`
* `title`

# `hide_button`

## Attributes

* `card_id` (`:any`) (required)

# `show_more_button`

## Attributes

* `card_id` (`:any`) (required)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
