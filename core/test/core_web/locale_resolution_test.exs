defmodule CoreWeb.LocaleResolutionTest do
  @moduledoc """
  Verifies that the browser pipeline's locale resolution honours the
  Accept-Language header for anonymous visitors while keeping the
  session value as the higher-priority source.
  """

  use CoreWeb.ConnCase, async: true

  @plug_opts Cldr.Plug.PutLocale.init(
               apps: [
                 cldr: CoreWeb.Cldr,
                 gettext: :global,
                 gettext: CoreWeb.Gettext,
                 gettext: Timex.Gettext
               ],
               from: [:session, :accept_language],
               default: "en"
             )

  defp call_plug(conn) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Cldr.Plug.PutLocale.call(@plug_opts)
  end

  describe "Cldr.Plug.PutLocale (browser pipeline config)" do
    test "uses session locale when present" do
      build_conn(:get, "/")
      |> Plug.Test.init_test_session(%{cldr_locale: "nl"})
      |> Cldr.Plug.PutLocale.call(@plug_opts)

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "session locale wins over Accept-Language" do
      build_conn(:get, "/")
      |> Plug.Conn.put_req_header("accept-language", "de-DE,de;q=0.9")
      |> Plug.Test.init_test_session(%{cldr_locale: "nl"})
      |> Cldr.Plug.PutLocale.call(@plug_opts)

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "falls back to Accept-Language when no session locale" do
      build_conn(:get, "/")
      |> Plug.Conn.put_req_header("accept-language", "nl-NL,nl;q=0.9,en;q=0.8")
      |> call_plug()

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "picks first supported language from Accept-Language q-values" do
      build_conn(:get, "/")
      |> Plug.Conn.put_req_header("accept-language", "fr;q=0.9,nl;q=0.8,en;q=0.5")
      |> call_plug()

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "falls back to default when Accept-Language has no supported language" do
      build_conn(:get, "/")
      |> Plug.Conn.put_req_header("accept-language", "fr-FR,fr;q=0.9,ja;q=0.8")
      |> call_plug()

      assert "en" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "falls back to default when Accept-Language header is absent" do
      build_conn(:get, "/")
      |> call_plug()

      assert "en" == Gettext.get_locale(CoreWeb.Gettext)
    end
  end
end
