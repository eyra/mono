# `Systems.Content.Adaptable`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/content/adaptable.ex#L1)

Adaptable layout system that adjusts presentation based on item count.

## Layout Behavior

| Item Count | Layout           | Navigation UI          | Add Button(s)                    |
|------------|------------------|------------------------|----------------------------------|
| 0          | Empty state      | None                   | Buttons for each creatable type  |
| 1          | Direct display   | None                   | Single "+" if creatables exist   |
| 2-5        | Tabbed           | Segmented control      | Single "+" to right of tabs      |
| >5         | Grouped tabs     | Segmented by type      | Per-group "+" buttons            |

## Usage

```elixir
alias Systems.Content.Adaptable

items = [
  Adaptable.Item.new(:org_1, :organisation, "VU Amsterdam", element: element),
  Adaptable.Item.new(:org_2, :organisation, "TU Delft", element: element)
]

creatables = [
  Adaptable.Creatable.new(:organisation, "Organisation", %{type: :send, event: "create"})
]

<.adaptable_layout
  socket={@socket}
  items={items}
  creatables={creatables}
  tabbar_id="my_tabbar"
/>
```

# `auth_module`

# `handle_info`

# `layout`

## Attributes

* `socket` (`:map`) (required)
* `items` (`:list`) (required)
* `creatables` (`:list`) - Defaults to `[]`.
* `tabbar_id` (`:any`) (required)
* `initial_item` (`:any`) - Defaults to `nil`.
* `empty_state` (`:map`) - Defaults to `nil`.
* `toolbar_buttons` (`:list`) - Defaults to `[]`.
* `area_type` (`:atom`) - Defaults to `:content`.

# `print_auth_roles`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
