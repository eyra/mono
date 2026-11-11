# `Frameworks.Pixel.RichText`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/rich_text.ex#L1)

Cleans the HTML of the rich-text editor (Trix, `Frameworks.Pixel.Form.wysiwyg_area/1`).

Every rich-text field goes through `clean_change/2` when it is saved (its
changeset) and through `clean/1` when it is shown
(`Frameworks.Pixel.WysiwygAreaHelpers.render_wysiwyg/1`), so text stored
before cleaning existed is covered too.

`clean/1` keeps the tags and attributes the editor produces and removes
everything else: other tags (their text stays), `script`, `style` and similar
tags with their content, comments, event and `style` attributes, and links or
images with an unsafe address. An image whose address is removed is removed
with its attachment. Every link opens in a new tab.

# `clean`

`html` with only the markup of the rich-text editor. `nil` stays `nil`.

# `clean_change`

Cleans the change of `field`. Text longer than `max_bytes/0` is an error
instead, and isn't cleaned; so is text that is longer than that once
cleaned.

# `clean_stored`

Cleans the complete stored text for display, including legacy values above
`max_bytes/0`. Existing content must remain readable in full. New writes are
bounded by `clean_change/2`, which checks both raw and cleaned sizes.

# `max_bytes`

The largest rich text, in bytes, a field accepts.

# `too_large?`

Whether `html` is over `max_bytes/0`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
