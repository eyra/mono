# `Systems.Content.Html`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/content/html.ex#L1)

# `adaptable_layout`

Adaptable layout that adjusts based on item count.

See `Systems.Content.Adaptable` for full documentation.

## Attributes

* `socket` (`:map`) (required)
* `items` (`:list`) (required)
* `creatables` (`:list`) - Defaults to `[]`.
* `tabbar_id` (`:any`) (required)
* `initial_item` (`:any`) - Defaults to `nil`.
* `empty_state` (`:map`) - Defaults to `nil`.
* `toolbar_buttons` (`:list`) - Defaults to `[]`.
* `area_type` (`:atom`) - Defaults to `:content`.

# `auth_module`

# `context_menu`

## Attributes

* `items` (`:list`) (required)
* `target` (`:any`) - Defaults to `""`.

# `handle_info`

# `live_stripped`

## Attributes

* `socket` (`:map`) (required)
* `title` (`:string`) - Defaults to `nil`.
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `modal_toolbar_buttons` (`:list`) - Defaults to `[]`.
## Slots

* `inner_block` (required)

# `live_website`

## Attributes

* `socket` (`:map`) (required)
* `user` (`:map`) (required)
* `user_agent` (`:map`) (required)
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `modal_toolbar_buttons` (`:list`) - Defaults to `[]`.
* `include_right_sidepadding?` (`:boolean`) - Defaults to `true`.
## Slots

* `hero` (required)
* `inner_block` (required)

# `live_workspace`

## Attributes

* `socket` (`:map`) (required)
* `title` (`:string`) - Defaults to `nil`.
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `modal_toolbar_buttons` (`:list`) - Defaults to `[]`.
## Slots

* `top_bar`
* `inner_block` (required)

# `management_page`

## Attributes

* `socket` (`:map`) (required)
* `title` (`:string`) (required)
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `tabs` (`:list`) (required)
* `tabbar_id` (`:atom`) (required)
* `initial_tab` (`:string`) (required)
* `show_errors` (`:string`) (required)
* `actions` (`:list`) (required)
* `more_actions` (`:list`) - Defaults to `[]`.
* `breadcrumbs` (`:list`) (required)

# `print_auth_roles`

# `tabbar_page`

## Attributes

* `socket` (`:map`) (required)
* `title` (`:string`) (required)
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `tabs` (`:list`) (required)
* `tabbar_id` (`:atom`) (required)
* `initial_tab` (`:string`) (required)
* `show_errors` (`:string`) (required)

# `tabbar_page_breadcrumbs`

## Attributes

* `socket` (`:map`) (required)
* `title` (`:string`) (required)
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `tabs` (`:list`) (required)
* `tabbar_id` (`:atom`) (required)
* `initial_tab` (`:string`) (required)
* `show_errors` (`:string`) (required)
* `breadcrumbs` (`:list`) - Defaults to `[]`.

# `tabbar_page_title`

A tabbar page with a title bar that includes an optional back button.
The title is displayed prominently, with a back arrow if back_path is provided.
Tabs are centered below the title bar.

## Attributes

* `socket` (`:map`) (required)
* `title` (`:string`) (required)
* `menus` (`:map`) (required)
* `modal` (`:map`) (required)
* `tabs` (`:list`) (required)
* `tabbar_id` (`:atom`) (required)
* `initial_tab` (`:string`) (required)
* `show_errors` (`:string`) (required)
* `back_path` (`:string`) - Defaults to `nil`.

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
