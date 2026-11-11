# `Frameworks.Pixel`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel.ex#L1)

Mica's UI framework. `use Frameworks.Pixel` brings Pixel's helpers and aliases
into a view.

Prism's components are function components of this module (`Pixel.button/1`,
`Pixel.tag/1`, …), built from Prism's design while Mica compiles. See
`Prism.Generator.Phoenix`.

# `button`

The design's `button` component.
## Attributes

* `variant` (`:atom`) - One of `:primary`, `:secondary`, `:plain`, `:link`, `:text`, `:soft`, `:icon`. Must be one of `:primary`, `:secondary`, `:plain`, `:link`, `:text`, `:soft`, or `:icon`.
* `tone` (`:atom`) - One of `:accent`, `:success`, `:warning`, `:danger`, `:neutral`, `:highlight`. Defaults to `:accent`. Must be one of `:accent`, `:success`, `:warning`, `:danger`, `:neutral`, or `:highlight`.
* `padded` (`:boolean`) - While true, adds `prism-button--padded` with variant `:plain` or `:text`. Defaults to `true`.
* `icon_position` (`:atom`) - The icon part's side of the content: `:start` or `:end`. Defaults to `:start`. Must be one of `:start`, or `:end`.
* `disabled` (`:boolean`) - Defaults to `false`.
* `loading` (`:boolean`) - Defaults to `false`.
* `as` (`:string`) - The element. Defaults to `"button"`. Must be one of `"button"`, `"a"`, `"span"`, or `"div"`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted. Supports all globals plus: `["type", "form", "formaction", "formenctype", "formmethod", "formnovalidate", "formtarget", "name", "value", "autofocus", "href", "target", "rel", "download"]`.
## Slots

* `icon` - The icon part; its attributes go on the part's element.
* `inner_block`

# `checkbox`

The design's `checkbox` component.
## Attributes

* `disabled` (`:boolean`) - Defaults to `false`.
* `checked` (`:boolean`) - Defaults to `false`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted. Supports all globals plus: `["accept", "autocomplete", "autofocus", "form", "list", "max", "maxlength", "min", "minlength", "multiple", "name", "pattern", "placeholder", "readonly", "required", "size", "step", "type", "value"]`.

# `field`

The design's `field` component.
## Attributes

* `variant` (`:atom`) - One of `:inverse`. Must be one of `:inverse`.
* `invalid` (`:boolean`) - Defaults to `false`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `label` - The label part; its attributes go on the part's element.
* `inner_block`
* `error_message` - The error_message part; its attributes go on the part's element.

# `image_picker`

The design's `image_picker` component.
## Attributes

* `shape` (`:atom`) - One of `:rectangular`, `:round`. Defaults to `:rectangular`. Must be one of `:rectangular`, or `:round`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `preview` - The preview part; its attributes go on the part's element.
* `button` - The button part: the app's own button component, in its place.

# `message_bar`

The design's `message_bar` component.
## Attributes

* `tone` (`:atom`) - One of `:info`, `:success`, `:warning`, `:danger`. Defaults to `:info`. Must be one of `:info`, `:success`, `:warning`, or `:danger`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `inner_block`

# `radio`

The design's `radio` component.
## Attributes

* `disabled` (`:boolean`) - Defaults to `false`.
* `checked` (`:boolean`) - Defaults to `false`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted. Supports all globals plus: `["accept", "autocomplete", "autofocus", "form", "list", "max", "maxlength", "min", "minlength", "multiple", "name", "pattern", "placeholder", "readonly", "required", "size", "step", "type", "value"]`.
## Slots

* `inner_block`

# `radio_group`

The design's `radio_group` component.
## Attributes

* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `inner_block`

# `select`

The design's `select` component.
## Attributes

* `variant` (`:atom`) - One of `:inverse`. Must be one of `:inverse`.
* `disabled` (`:boolean`) - Defaults to `false`.
* `invalid` (`:boolean`) - Defaults to `false`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `inner_block`
* `icon` - The icon part; its attributes go on the part's element.
* `option` - One option; its attributes go on the option's element, and `selected` adds its selected look.

# `spinner`

The design's `spinner` component.
## Attributes

* `variant` (`:atom`) - One of `:accent`, `:inverse`. Must be one of `:accent`, or `:inverse`.
* `size` (`:integer`) - One of `16`, `20`, `24`, `32`. Defaults to `24`. Must be one of `16`, `20`, `24`, or `32`.
* `progress` (`:any`) - A number from 0 to 100 (clamped), or `nil`: with one, adds `prism-spinner--progress` and `role="progressbar"`. Defaults to `nil`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.

# `step_indicator`

The design's `step_indicator` component.
## Attributes

* `status` (`:atom`) - One of `:incomplete`, `:current`, `:complete`. Defaults to `:incomplete`. Must be one of `:incomplete`, `:current`, or `:complete`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `inner_block`

# `tag`

The design's `tag` component.
## Attributes

* `tone` (`:atom`) - One of `:accent`, `:success`, `:warning`, `:danger`, `:neutral`. Defaults to `:accent`. Must be one of `:accent`, `:success`, `:warning`, `:danger`, or `:neutral`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted.
## Slots

* `inner_block`

# `text_area`

The design's `text_area` component.
## Attributes

* `variant` (`:atom`) - One of `:inverse`. Must be one of `:inverse`.
* `editor` (`:atom`) - One of `:plain`, `:rich_text`. Defaults to `:plain`. Must be one of `:plain`, or `:rich_text`.
* `disabled` (`:boolean`) - Defaults to `false`.
* `invalid` (`:boolean`) - Defaults to `false`.
* `value` (`:any`) - Defaults to `nil`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted. Supports all globals plus: `["autocomplete", "autofocus", "cols", "form", "maxlength", "minlength", "name", "placeholder", "readonly", "required", "rows", "wrap"]`.
## Slots

* `inner_block`

# `text_field`

The design's `text_field` component.
## Attributes

* `variant` (`:atom`) - One of `:inverse`. Must be one of `:inverse`.
* `disabled` (`:boolean`) - Defaults to `false`.
* `invalid` (`:boolean`) - Defaults to `false`.
* `class` (`:any`) - Classes after the component's own. Defaults to `nil`.
* Global attributes are accepted. Supports all globals plus: `["accept", "autocomplete", "autofocus", "form", "list", "max", "maxlength", "min", "minlength", "multiple", "name", "pattern", "placeholder", "readonly", "required", "size", "step", "type", "value", "checked"]`.
## Slots

* `prefix` - The prefix part; its attributes go on the part's element.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
