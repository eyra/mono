# `MicaWeb.Live.Element`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/element.ex#L1)

Thin wrapper around `LiveNest.Element.prepare_live_view/3` that stamps the
parent's current process locale into the session passed to the embedded view.

Embedded LiveViews run in a separate process from their parent and do not
inherit the parent's Gettext locale. Without this propagation, the embedded
view's `Hook.Locale` would have no session key to read and would fall back
to the BEAM default (`en`) — causing pages to render in English even when
the parent has set a different locale (e.g. `nl` for a PANL participant,
or the assignment language for a crew page).

The injected key is read by `MicaWeb.Live.Hook.Locale` when the standard
Cldr session key is absent (which is always the case for embedded views).

# `prepare_live_view`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
