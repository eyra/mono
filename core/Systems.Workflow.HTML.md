# `Systems.Workflow.HTML`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/workflow/html.ex#L1)

# `auth_module`

# `collapsed`

## Attributes

* `title` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block`

# `handle_info`

# `print_auth_roles`

# `version`

# `work_list_item`

## Attributes

* `id` (`:any`) (required)
* `title` (`:map`) (required)
* `description` (`:map`) - Defaults to `nil`.
* `group` (`:atom`) - Defaults to `nil`.
* `status` (`:atom`) - Defaults to `:pending`.
* `index` (`:integer`) (required)
* `selected?` (`:boolean`) - Defaults to `true`.
* `event` (`:string`) - Defaults to `"work_item_selected"`.
* `target` (`:any`) - Defaults to `""`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
