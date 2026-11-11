# `MicaWeb.Live.Hook.Language`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/hook/language.ex#L1)

LiveView hook that applies language/locale from live_context.

This hook runs after Context hook and checks if the context contains
a `language` key. If present, it applies the locale for Gettext translations.

This is primarily used for participant-facing views (CrewPage and its children)
where the assignment's language setting should override the default locale.

# `on_mount`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
