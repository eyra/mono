defmodule CoreWeb.Plug.AcceptLanguageTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn, only: [get_session: 2, put_req_header: 3]

  alias CoreWeb.Plug.AcceptLanguage

  test "stores the accept-language header in the session" do
    conn =
      :get
      |> conn("/")
      |> init_test_session(%{})
      |> put_req_header("accept-language", "nl-NL,nl;q=0.9")
      |> AcceptLanguage.call(%{})

    assert get_session(conn, :accept_language) == "nl-NL,nl;q=0.9"
  end

  test "leaves the session untouched when the header is missing" do
    conn =
      :get
      |> conn("/")
      |> init_test_session(%{})
      |> AcceptLanguage.call(%{})

    assert get_session(conn, :accept_language) == nil
  end
end
