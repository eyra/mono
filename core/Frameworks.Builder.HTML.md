# `Frameworks.Builder.HTML`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/builder/html.ex#L1)

# `auth_module`

# `collapsed`

## Attributes

* `title` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block`

# `handle_info`

# `library`

## Attributes

* `title` (`:string`) (required)
* `description` (`:string`) (required)
* `items` (`:list`) (required)

# `library_item`

## Attributes

* `id` (`:any`) (required)
* `type` (`:any`) (required)
* `title` (`:string`) (required)
* `description` (`:string`) (required)
* `tags` (`:list`) - Defaults to `nil`.

# `print_auth_roles`

# `version`

# `work_list_item`

## Attributes

* `id` (`:any`) (required)
* `title` (`:map`) (required)
* `description` (`:map`) - Defaults to `nil`.
* `icon` (`:string`) (required)
* `status` (`:atom`) - Defaults to `:pending`.
* `index` (`:integer`) (required)
* `selected?` (`:boolean`) - Defaults to `true`.
* `event` (`:string`) - Defaults to `"work_item_selected"`.
* `target` (`:any`) - Defaults to `""`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
