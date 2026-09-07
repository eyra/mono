defmodule CoreWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      use Gettext, backend: CoreWeb.Gettext

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
  """
  use Gettext.Backend, otp_app: :core

  def handle_missing_translation(locale, domain, msgctxt, msgid, bindings) do
    case fallback_locale(locale) do
      nil -> super(locale, domain, msgctxt, msgid, bindings)
      fallback -> as_default(lgettext(fallback, domain, msgctxt, msgid, bindings))
    end
  end

  def handle_missing_plural_translation(
        locale,
        domain,
        msgctxt,
        msgid,
        msgid_plural,
        n,
        bindings
      ) do
    case fallback_locale(locale) do
      nil ->
        super(locale, domain, msgctxt, msgid, msgid_plural, n, bindings)

      fallback ->
        as_default(lngettext(fallback, domain, msgctxt, msgid, msgid_plural, n, bindings))
    end
  end

  defp fallback_locale(locale) do
    case Application.get_env(:core, :gettext_fallback_locale) do
      ^locale -> nil
      "" -> nil
      fallback -> fallback
    end
  end

  defp as_default({:ok, translated}), do: {:default, translated}
  defp as_default(other), do: other
end
