# `Frameworks.Pixel.Hero`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/hero.ex#L1)

The hero is to be used as a large decorative header with page title.

# `banner`

## Attributes

* `icon_url` (`:string`) (required)
* `illustration` (`:string`) - Defaults to `"/images/illustration2.svg"`.
* `bg_color` (`:string`) - Defaults to `"bg-grey1"`.

# `dynamic`

## Attributes

* `type` (`:atom`) (required)
* `params` (`:map`) (required)

# `illustration1`

## Attributes

* `title` (`:string`) (required)
* `subtitle` (`:string`) - Defaults to `nil`.
* `illustration` (`:any`) - Defaults to `"illustration.svg"`.
* `text_color` (`:string`) - Defaults to `"text-white"`.
* `bg_color` (`:string`) - Defaults to `"bg-primary"`.

# `illustration2`

## Attributes

* `title` (`:string`) (required)
* `illustration` (`:any`) - Defaults to `"illustration.svg"`.
* `text_color` (`:string`) - Defaults to `"text-white"`.
* `bg_color` (`:string`) - Defaults to `"bg-primary"`.
* `caption` (`:string`) - Defaults to `nil`.

# `image_banner`

## Attributes

* `title` (`:string`) (required)
* `subtitle` (`:string`) (required)
* `image_info` (`:any`) (required)
* `logo_url` (`:string`) - Defaults to `nil`.
* `text_color` (`:string`) - Defaults to `"text-white"`.

# `image_large`

## Attributes

* `title` (`:string`) (required)
* `subtitle` (`:string`) (required)
* `image_info` (`:any`) (required)
* `text_color` (`:string`) - Defaults to `"text-white"`.
## Slots

* `call_to_action`

# `landing_page`

## Attributes

* `title` (`:string`) (required)
* `illustration` (`:any`) - Defaults to `"illustration.svg"`.
* `text_color` (`:string`) - Defaults to `"text-white"`.
* `bg_color` (`:string`) - Defaults to `"bg-primary"`.
* `caption` (`:string`) - Defaults to `nil`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
