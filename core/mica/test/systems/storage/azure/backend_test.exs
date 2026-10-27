defmodule Systems.Storage.Azure.BackendTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.Azure.Backend

  describe "filename/1" do
    test "empty identifier" do
      assert ".json" = Backend.filename([])
    end

    test "single identifier" do
      assert "participant=1.json" = Backend.filename([[:participant, 1]])
    end

    test "multiple identifiers" do
      identifier = [[:assignment, 1], [:participant, "abc"], [:source, "test"]]
      assert "assignment=1_participant=abc_source=test.json" = Backend.filename(identifier)
    end
  end

  describe "url/2" do
    @endpoint %{"account_name" => "acc", "container" => "box", "sas_token" => "?sv=1&sig=s"}

    test "puts the file in the container, followed by the sas token" do
      assert {:ok, "https://acc.blob.core.windows.net/box/assignment=1_key=k%20v.json?sv=1&sig=s"} =
               Backend.url(@endpoint, "assignment=1_key=k v.json")
    end

    test "keeps a slash in the filename inside the container" do
      assert {:ok, url} = Backend.url(@endpoint, "../b.json")
      assert %URI{path: "/box/.._b.json"} = URI.parse(url)
    end

    test "keeps a question mark in the filename out of the query" do
      assert {:ok, url} = Backend.url(@endpoint, "b?x=1.json")
      assert %URI{path: "/box/b%3Fx=1.json", query: "sv=1&sig=s"} = URI.parse(url)
    end

    test "keeps a question mark in an identifier value out of the query" do
      filename = Backend.filename([[:key, "k?x=1"]])

      assert {:ok, url} = Backend.url(@endpoint, filename)
      assert %URI{path: "/box/key=k%3Fx=1.json", query: "sv=1&sig=s"} = URI.parse(url)
    end
  end
end
