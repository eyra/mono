# `MicaWeb.Gettext`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/gettext.ex#L1)

A module providing Internationalization with a gettext-based API.

By using [Gettext](https://hexdocs.pm/gettext),
your module gains a set of macros for translations, for example:

    use Gettext, backend: MicaWeb.Gettext

    # Simple translation
    gettext("Here is the string to translate")

    # Plural translation
    ngettext("Here is the string to translate",
             "Here are the strings to translate",
             3)

    # Domain-based translation
    dgettext("errors", "Here is the error message to translate")

Msgids in this app are dotted keys rather than English sentences, so an
untranslated string renders as a raw key. Set `GETTEXT_FALLBACK_LOCALE` to
serve another locale's text instead; leave it unset or empty to keep the raw
keys visible, which is what you want when hunting missing translations.

See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.

# `handle_missing_bindings`

# `handle_missing_plural_translation`

# `handle_missing_translation`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
