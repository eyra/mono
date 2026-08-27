defmodule CoreWeb.LocaleResolutionTest do
  @moduledoc """
  Verifies that the browser pipeline's locale resolution honours the
  Accept-Language header for anonymous visitors while keeping the
  session value as the higher-priority source.
  """

  use CoreWeb.ConnCase, async: true

  alias Cldr.Plug.PutLocale
  alias CoreWeb.Plug.PersistLocale

  @plug_opts PutLocale.init(
               apps: [
                 cldr: CoreWeb.Cldr,
                 gettext: :global,
                 gettext: CoreWeb.Gettext,
                 gettext: Timex.Gettext
               ],
               from: [:session, :accept_language],
               default: "en"
             )

  @session_key PutLocale.session_key()

  defp call_plug(conn) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> PutLocale.call(@plug_opts)
  end

  describe "Cldr.Plug.PutLocale (browser pipeline config)" do
    test "uses session locale when present" do
      :get
      |> build_conn("/")
      |> Plug.Test.init_test_session(%{@session_key => "nl"})
      |> PutLocale.call(@plug_opts)

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "session locale wins over Accept-Language" do
      :get
      |> build_conn("/")
      |> Plug.Conn.put_req_header("accept-language", "de-DE,de;q=0.9")
      |> Plug.Test.init_test_session(%{@session_key => "nl"})
      |> PutLocale.call(@plug_opts)

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "falls back to Accept-Language when no session locale" do
      :get
      |> build_conn("/")
      |> Plug.Conn.put_req_header("accept-language", "nl-NL,nl;q=0.9,en;q=0.8")
      |> call_plug()

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "picks first supported language from Accept-Language q-values" do
      :get
      |> build_conn("/")
      |> Plug.Conn.put_req_header("accept-language", "fr;q=0.9,nl;q=0.8,en;q=0.5")
      |> call_plug()

      assert "nl" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "falls back to default when Accept-Language has no supported language" do
      :get
      |> build_conn("/")
      |> Plug.Conn.put_req_header("accept-language", "fr-FR,fr;q=0.9,ja;q=0.8")
      |> call_plug()

      assert "en" == Gettext.get_locale(CoreWeb.Gettext)
    end

    test "falls back to default when Accept-Language header is absent" do
      :get
      |> build_conn("/")
      |> call_plug()

      assert "en" == Gettext.get_locale(CoreWeb.Gettext)
    end
  end

  # Regression coverage for FX#9867378604 — the LiveView mount runs in
  # a separate process from the HTTP request and reads the session over
  # the WebSocket. Without persisting the Cldr-resolved locale into the
  # session, anonymous visitors see a NL → EN flash between the initial
  # server render and the LiveView connect.
  describe "CoreWeb.Plug.PersistLocale" do
    test "writes the Accept-Language-derived locale to the session" do
      conn =
        :get
        |> build_conn("/")
        |> Plug.Conn.put_req_header("accept-language", "nl-NL,nl;q=0.9")
        |> call_plug()
        |> PersistLocale.call([])

      assert Plug.Conn.get_session(conn, @session_key) == "nl"
    end

    test "writes the session-derived locale back to the session" do
      conn =
        :get
        |> build_conn("/")
        |> Plug.Test.init_test_session(%{@session_key => "de"})
        |> PutLocale.call(@plug_opts)
        |> PersistLocale.call([])

      assert Plug.Conn.get_session(conn, @session_key) == "de"
    end

    test "is a no-op when Cldr couldn't resolve a locale" do
      # No accept-language header, no session — Cldr falls back to the
      # default. We still expect PersistLocale to write something safe.
      conn =
        :get
        |> build_conn("/")
        |> call_plug()
        |> PersistLocale.call([])

      assert Plug.Conn.get_session(conn, @session_key) == "en"
    end
  end
end
