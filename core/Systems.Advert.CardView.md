# `Systems.Advert.CardView`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/advert/card_view.ex#L1)

A large eye-catcher meant to call a user into taking an action.

# `auth_module`

# `basic`

## Attributes

* `id` (`:any`) (required)
* `icon_url` (`:string`) - Defaults to `nil`.
* `image_info` (`:map`) (required)
* `title` (`:string`) (required)
* `tags` (`:list`) - Defaults to `nil`.
* `label` (`:map`) - Defaults to `nil`.
* `info` (`:list`) - Defaults to `[]`.
* `bg_color` (`:string`) - Defaults to `"grey1"`.
* `text_color` (`:string`) - Defaults to `"text-white"`.
* `label_type` (`:string`) - Defaults to `"tertiary"`.
* `tag_type` (`:string`) - Defaults to `"primary"`.
* `info1_color` (`:string`) - Defaults to `"text-tertiary"`.
* `info2_color` (`:string`) - Defaults to `"text-white"`.
* `left_actions` (`:list`) - Defaults to `nil`.
* `right_actions` (`:list`) - Defaults to `nil`.
* `target` (`:any`) (required)

# `dynamic`

## Attributes

* `card` (`:map`) (required)
* `target` (`:any`) (required)

# `handle_info`

# `primary`

## Attributes

* `card` (`:any`) (required)
* `target` (`:any`) (required)

# `print_auth_roles`

# `secondary`

## Attributes

* `card` (`:any`) (required)
* `target` (`:any`) (required)

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
