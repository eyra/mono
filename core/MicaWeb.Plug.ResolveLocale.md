# `MicaWeb.Plug.ResolveLocale`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/hook/locale.ex#L69)

Pins the session locale to English for creators; clears it for
everyone else so the rest of the locale pipeline (Cldr, Hook.Locale,
Gettext) resolves from Accept-Language.

Runs after `Systems.Account.Plug` (which assigns `current_user` for
authenticated non-restricted users) and before `Cldr.Plug.PutLocale`.
Anonymous visitors and signed-in participants honor the browser
locale; only signed-in creators get pinned to English.

# `call`

# `init`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
