# `Systems.Manual.Html`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/manual/html.ex#L1)

# `auth_module`

# `chapter_desktop`

## Attributes

* `id` (`:integer`) (required)
* `title` (`:string`) (required)
* `label` (`:string`) - Defaults to `nil`.
* `pages` (`:list`) (required)
* `selected_page` (`:map`) (required)
* `fullscreen_button` (`:map`) - Defaults to `nil`.
* `select_page_event` (`:string`) (required)
* `select_page_target` (`:any`) (required)

# `chapter_list`

## Attributes

* `items` (`:list`) (required)
* `selected_chapter_id` (`:integer`) - Defaults to `nil`.
* `target` (`:any`) (required)

# `chapter_list_item`

## Attributes

* `id` (`:integer`) (required)
* `title` (`:string`) (required)
* `selected` (`:boolean`) - Defaults to `false`.
* `target` (`:any`) (required)
* `number` (`:integer`) (required)

# `chapter_mobile`

## Attributes

* `id` (`:integer`) (required)
* `title` (`:string`) (required)
* `label` (`:string`) - Defaults to `nil`.
* `indicator` (`:string`) - Defaults to `nil`.
* `selected_page` (`:map`) (required)
* `fullscreen_button` (`:map`) - Defaults to `nil`.

# `handle_info`

# `page`

## Attributes

* `id` (`:string`) (required)
* `page` (`:map`) (required)
* `indicator` (`:string`) - Defaults to `nil`.
* `fullscreen_button` (`:map`) - Defaults to `nil`.
* `padding` (`:string`) - Defaults to `""`.

# `page_list`

## Attributes

* `items` (`:list`) (required)
* `selected_page` (`:map`) (required)
* `select_page_event` (`:string`) (required)
* `select_page_target` (`:any`) (required)

# `page_list_item`

## Attributes

* `id` (`:integer`) (required)
* `title` (`:string`) (required)
* `selected` (`:boolean`) - Defaults to `false`.
* `target` (`:any`) (required)
* `number` (`:integer`) (required)
* `select_page_event` (`:string`) (required)
* `select_page_target` (`:any`) (required)

# `print_auth_roles`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
