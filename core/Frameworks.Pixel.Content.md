# `Frameworks.Pixel.Content`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/content.ex#L1)

# `item`

## Attributes

* `id` (`:string`) (required)
* `path` (`:string`) (required)
* `title` (`:string`) (required)
* `subtitle` (`:string`) (required)
* `quick_summary` (`:string`) (required)
* `tag` (`:map`) - Defaults to `%{type: nil, text: nil}`.
* `image` (`:map`) - Defaults to `nil`.
* `title_css` (`:string`) - Defaults to `"font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"`.
* `subtitle_css` (`:string`) - Defaults to `"text-bodysmall md:text-bodymedium font-body text-grey2 whitespace-pre-wrap"`.

# `list`

## Attributes

* `items` (`:list`) (required)

# `tag`

## Attributes

* `type` (`:atom`) (required)
* `text` (`:string`) (required)
* `size` (`:string`) - Defaults to `"L"`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
