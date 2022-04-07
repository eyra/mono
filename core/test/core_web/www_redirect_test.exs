defmodule CoreWeb.WWWRedirect.Test do
  use ExUnit.Case, async: true
  use Plug.Test
  alias CoreWeb.WWWRedirect

  def call(conn) do
    WWWRedirect.call(conn, [])
  end

  describe "call/1" do
    test "returns redirected conn" do
      assert %{
               status: 302,
               resp_headers: [
                 {"content-type", "text/html; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"},
                 {"location", "https://eyra.co/"}
               ]
             } = call(conn(:get, "https://www.eyra.co/"))
    end

    test "returns untouched conn" do
      assert %{
               status: nil,
               resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}]
             } = call(conn(:get, "https://eyra.co/"))
    end
  end
end
