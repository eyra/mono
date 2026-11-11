# `MicaWeb.Live.FormHelpers`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/form_helpers.ex#L1)

Reusable form helpers with auto-save functionality.

Provides convenience functions for form handling and auto-save that work
across different view types (live_component, embedded_live_view, etc.).

## Requirements

This module requires `MicaWeb.Live.FlashHelpers` to be used first for
flash message functions.

## Usage

    use MicaWeb.Live.FlashHelpers
    use MicaWeb.Live.FormHelpers

## Functions

- `auto_save/2` - Validates changeset and persists if valid, showing flash feedback

---

*Consult [api-reference.md](api-reference.md) for complete listing*
