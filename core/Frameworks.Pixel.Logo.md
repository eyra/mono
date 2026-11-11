# `Frameworks.Pixel.Logo`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/logo.ex#L1)

Logo component for product, platform, and pool logos.

Directory structure:
- /images/logos/products/  - Eyra's own product family (Next, Eyra, Self, Yoda, ...)
- /images/logos/platforms/ - External third-party brands (Google, Apple, TikTok, Surfconext, ...)
- /images/logos/pools/     - Participant pool brand marks (Panl, LISS Panel, ...) —
                             neither Eyra products nor external third parties.
                             Each pool ships two assets: `<slug>.svg` (icon-only
                             avatar) and `<slug>_wide.svg` (wordmark for wider
                             contexts).

Product logo variants:
- {name}.svg - Icon only (scalable)
- {name}_wide.svg - With integrated text (hand-positioned)
- {name}_standing.svg - Vertical variant (if exists)

Platform logo variants:
- {name}.svg - Circle variant (scalable, text-free)
- {name}_square.svg - Square variant (scalable, text-free)

Pool logo variants:
- {name}.svg - Icon-only avatar (default)
- {name}_wide.svg - Wordmark (with integrated text)

# `menu_home`

## Attributes

* `name` (`:atom`) (required)
* `size` (`:atom`) (required) - Must be one of `:default`, or `:wide`.

# `path`

# `platform`

## Attributes

* `platform` (`:atom`) (required)
* `variant` (`:atom`) - Defaults to `:default`. Must be one of `:default`, or `:square`.
* `class` (`:string`) - Defaults to `""`.

# `pool`

## Attributes

* `name` (`:any`) (required)
* `variant` (`:any`) - Defaults to `:default`.
* `class` (`:string`) - Defaults to `""`.

# `product`

## Attributes

* `name` (`:atom`) (required)
* `variant` (`:atom`) - Defaults to `:default`. Must be one of `:default`, `:wide`, or `:standing`.
* `class` (`:string`) - Defaults to `""`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
