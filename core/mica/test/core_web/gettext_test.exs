defmodule CoreWeb.GettextTest do
  use ExUnit.Case, async: false

  use Gettext, backend: CoreWeb.Gettext

  @key "rewards_summary.donate.button"
  @untranslated_locale "zz"

  @plural_key "domain.match.banner.title.singular"
  @plural_key_other "domain.match.banner.title.plural"

  setup do
    original = Application.get_env(:core, :gettext_fallback_locale)
    on_exit(fn -> Application.put_env(:core, :gettext_fallback_locale, original) end)
    :ok
  end

  defp translate(locale), do: Gettext.with_locale(locale, fn -> dgettext("eyra-fund", @key) end)

  defp translate_plural(locale, count) do
    Gettext.with_locale(locale, fn ->
      dngettext("eyra-org", @plural_key, @plural_key_other, count)
    end)
  end

  defp payout_body(locale, amount) do
    Gettext.with_locale(locale, fn ->
      dgettext("eyra-fund", "rewards_summary.payout.handoff.body", amount: amount)
    end)
  end

  describe "without a fallback locale" do
    setup do
      Application.put_env(:core, :gettext_fallback_locale, nil)
      :ok
    end

    test "an untranslated string renders the raw key" do
      assert translate(@untranslated_locale) == @key
    end

    test "an untranslated plural string renders the raw keys" do
      assert translate_plural(@untranslated_locale, 1) == @plural_key
      assert translate_plural(@untranslated_locale, 3) == @plural_key_other
    end

    test "a translated string is unaffected" do
      assert translate("en") == "Donate"
    end
  end

  describe "with an empty fallback locale" do
    setup do
      Application.put_env(:core, :gettext_fallback_locale, "")
      :ok
    end

    test "an untranslated string renders the raw key" do
      assert translate(@untranslated_locale) == @key
    end
  end

  describe "with a fallback locale" do
    setup do
      Application.put_env(:core, :gettext_fallback_locale, "en")
      :ok
    end

    test "an untranslated string falls back to the fallback locale" do
      assert translate(@untranslated_locale) == "Donate"
    end

    test "an untranslated plural string falls back in both singular and plural form" do
      assert translate_plural(@untranslated_locale, 1) ==
               "1 account found on the Next platform that matches your domains"

      assert translate_plural(@untranslated_locale, 3) ==
               "3 accounts found on the Next platform that match your domains"
    end

    test "an untranslated string interpolates bindings into the fallback text" do
      assert payout_body(@untranslated_locale, "€15") =~ "€15"
      assert payout_body(@untranslated_locale, "€15") == payout_body("en", "€15")
    end

    test "a translated string keeps its own locale" do
      assert translate("nl") == "Doneren"
    end

    test "a key missing from the fallback locale too renders the raw key" do
      assert Gettext.with_locale(@untranslated_locale, fn ->
               dgettext("eyra-fund", "no.such.key.exists")
             end) == "no.such.key.exists"
    end
  end
end
