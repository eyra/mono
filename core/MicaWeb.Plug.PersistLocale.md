# `MicaWeb.Plug.PersistLocale`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/hook/locale.ex#L96)

Persists the locale that Cldr.Plug.PutLocale just resolved into the
session.

Cldr.Plug.PutLocale sets the locale on gettext/cldr process state but
doesn't write it back to the session. For anonymous visitors who land
on the site with an Accept-Language header, that means the LiveView
mount (which runs in a separate process and reads the session over
the WebSocket connect_info) can't see the resolved locale and falls
back to the default — causing a visible NL → EN flash between the
initial server render and LiveView connect.

This plug bridges the gap by writing the resolved locale into the
same session key Cldr.Plug.PutLocale reads from.

# `call`

# `init`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
