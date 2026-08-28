defmodule CoreWeb.GettextTest do
  use ExUnit.Case, async: false

  use Gettext, backend: CoreWeb.Gettext

  # Translated in en, empty in es.
  @key "rewards_summary.donate.button"

  setup do
    original = Application.get_env(:core, :gettext_fallback_locale)
    on_exit(fn -> Application.put_env(:core, :gettext_fallback_locale, original) end)
    :ok
  end

  defp translate(locale), do: Gettext.with_locale(locale, fn -> dgettext("eyra-fund", @key) end)

  describe "without a fallback locale" do
    setup do
      Application.put_env(:core, :gettext_fallback_locale, nil)
      :ok
    end

    test "an untranslated string renders the raw key" do
      assert translate("es") == @key
    end

    test "a translated string is unaffected" do
      assert translate("en") == "Donate"
    end
  end

  describe "with a fallback locale" do
    setup do
      Application.put_env(:core, :gettext_fallback_locale, "en")
      :ok
    end

    test "an untranslated string falls back to the fallback locale" do
      assert translate("es") == "Donate"
    end

    test "a translated string keeps its own locale" do
      assert translate("nl") == "Doneren"
    end

    test "a key missing from the fallback locale too renders the raw key" do
      assert Gettext.with_locale("es", fn ->
               dgettext("eyra-fund", "no.such.key.exists")
             end) == "no.such.key.exists"
    end
  end
end
