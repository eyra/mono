# `MicaWeb.LiveForm`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live_form.ex#L1)

A macro for creating live form components with auto-save functionality.

This module provides a complete setup for live components that need
form handling with automatic persistence and flash feedback.

## Usage

    use MicaWeb.LiveForm

This is equivalent to:

    use MicaWeb, :live_component_fabric
    use MicaWeb.Live.FlashHelpers
    use MicaWeb.Live.FormHelpers

Plus additional backward-compatible helpers for existing forms.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
