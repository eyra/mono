# `Frameworks.Pixel.InlineBlock`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/inline_block.ex#L1)

A self-contained content block with a border, used to visually
distinguish a specific context from surrounding content.

Renders a bordered container with a title and description on the left,
an optional icon on the right, and optional button/content below.
On small screens the icon sits next to the title only, with description
below at full width.

# `inline_block`

## Attributes

* `title` (`:string`) (required)
* `description` (`:string`) (required)
* `button` (`:map`) - Defaults to `nil`.
* `icon` (`:string`) - Defaults to `nil`.
## Slots

* `inner_block`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
