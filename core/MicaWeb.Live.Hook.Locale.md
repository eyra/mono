# `MicaWeb.Live.Hook.Locale`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/hook/locale.ex#L1)

Live hook that pins the LiveView process's locale.

The LiveView mount runs in a separate process from the HTTP request,
so neither Cldr.Plug.PutLocale nor the process-level gettext locale
from the initial request carries over. Without this hook, every
LiveView would inherit the BEAM default (`en`) and any page that
doesn't explicitly call `put_locale/1` would render in English even
when the session says otherwise.

Resolution rule:
  * Read the locale from the session — written by Cldr.Plug.PutLocale
    / Plug.PersistLocale for routed views, or stamped by
    Live.Element.prepare_live_view for embedded views.
  * Validate it against the configured Cldr set; fall back to English
    otherwise.

The decision of when to honor the browser locale vs. pin to EN lives
entirely in `MicaWeb.Plug.ResolveLocale`; this hook just trusts the
session.

# `get_locale`

# `on_mount`

# `optional_apply`

# `optional_apply`

# `put_locale`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
