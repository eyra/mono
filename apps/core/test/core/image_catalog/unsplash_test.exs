defmodule Core.ImageCatalog.Unsplash.HTTP.Test do
  use ExUnit.Case, async: true

  alias Core.ImageCatalog.Unsplash.HTTP

  setup do
    bypass = Bypass.open()
    Application.put_env(:core, :unsplash_endpoint, "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass}
  end

  describe "get/3" do
    test "returns parsed JSON", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"hello": "test"}>)
      end)

      assert HTTP.get("key", "/test", []) == {:ok, %{"hello" => "test"}}
    end
  end
end

defmodule Core.ImageCatalog.Unsplash.Test do
  use ExUnit.Case, async: true
  import Mox

  alias Core.ImageCatalog.Unsplash

  setup_all do
    Mox.defmock(Core.ImageCatalog.Unsplash.MockClient, for: Core.ImageCatalog.Unsplash.Client)
    Application.put_env(:core, :unsplash_client, Unsplash.MockClient)
    {:ok, mock: Unsplash.MockClient}
  end

  setup :verify_on_exit!

  describe "search/1" do
    test "returns ids", %{mock: mock} do
      mock
      |> expect(:get, fn _, "/search/photos", _ ->
        {:ok,
         %{
           "results" => [
             %{
               "urls" => %{"raw" => "http://example.org"},
               "user" => %{"username" => "tester", "name" => "Miss Test"},
               "blur_hash" => "asdf"
             }
           ]
         }}
      end)

      assert Unsplash.search("test") |> Enum.count() == 1
    end
  end

  describe "search_info/1" do
    test "returns image information", %{mock: mock} do
      mock
      |> expect(:get, fn _, "/search/photos", _ ->
        {:ok,
         %{
           "results" => [
             %{
               "urls" => %{"raw" => "http://example.org"},
               "user" => %{"username" => "tester", "name" => "Miss Test"},
               "blur_hash" => "asdf"
             }
           ]
         }}
      end)

      [info] = Unsplash.search_info("test", width: 200, height: 300)

      assert info.attribution ==
               {:safe,
                "Photo by <a href=\"https://unsplash.com/@tester=Core&utm_medium=referral\">Miss Test</a> on <a href=\"https://unsplash.com/?utm_source=Core&utm_medium=referral\">Unsplash</a>"}

      assert info.url =~ "example.org"
      assert info.srcset =~ " 2x,"
      assert info.blur_hash =~ "asdf"
    end
  end
end
