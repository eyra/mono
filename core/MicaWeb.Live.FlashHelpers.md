# `MicaWeb.Live.FlashHelpers`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/flash_helpers.ex#L1)

Reusable flash message helpers for LiveView and LiveComponent.

Provides convenience functions for showing flash messages that work
across different view types (live_component, embedded_live_view, etc.).

## Usage

    use MicaWeb.Live.FlashHelpers

## Functions

- `hide_flash/1` - Hides any visible flash message
- `flash_info/2` - Shows an info flash message
- `flash_error/1` - Shows a generic error flash message
- `flash_error/2` - Shows a custom error flash message
- `flash_persister_saved/1` - Shows the standard "Saved" message
- `flash_persister_error/1` - Shows the standard persister error message
- `flash_persister_error/2` - Shows a custom persister error message

---

*Consult [api-reference.md](api-reference.md) for complete listing*
