# `Frameworks.Pixel.AlertBanner`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/alert-banner.ex#L1)

# `action`

Action banner with title, subtitle, and action button.
Used for prompting users to take contextual actions.

## Attributes

* `title` (`:string`) (required)
* `subtitle` (`:string`) - Defaults to `nil`.
* `button` (`:map`) - Defaults to `nil`.

# `alert`

## Attributes

* `type` (`:atom`) - Defaults to `:info`. Must be one of `:success`, `:warning`, `:error`, or `:info`.
* `message` (`:string`) - Defaults to `nil`.
* `class` (`:string`) - Defaults to `""`.
## Slots

* `inner_block`

# `error`

Render a error alert

# `info`

Render a info alert

# `success`

Render a success alert

# `warning`

Render a warning alert

---

*Consult [api-reference.md](api-reference.md) for complete listing*
