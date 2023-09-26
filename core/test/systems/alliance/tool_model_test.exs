defmodule Systems.Alliance.ToolModelTest do
  use Core.DataCase, async: true

  alias Systems.{
    Alliance
  }

  describe "validate_url" do
    for url <-
          [
            Faker.Internet.url(),
            "https://example.org/test?a=<var>",
            "https://example.org/test?a=<first>&b=<second>",
            "https://example.org/test?a=some-NoN-v4r1a8l3"
          ] do
      test "allow #{url}" do
        changeset =
          Alliance.ToolModel.changeset(%Alliance.ToolModel{}, :auto_save, %{
            url: unquote(url)
          })

        assert changeset.valid?, changeset.errors
      end
    end

    for url <- [
          "http://example.org/alliance?a=<param",
          "http://example.org/alliance?b=<var with space>",
          "http://example.org/alliance?c=<var-with-dash>",
          "http://example.org/alliance?d=<unclosed&other=<var>"
        ] do
      test "disallow URL: #{url}" do
        changeset =
          Alliance.ToolModel.changeset(%Alliance.ToolModel{}, :auto_save, %{
            url: unquote(url)
          })

        refute changeset.valid?
      end
    end
  end

  describe "prepare_alliance_url" do
    test "URL without params stays the same" do
      assert Alliance.ToolModel.prepare_url("http://example.org/test?a=b", %{}) ==
               "http://example.org/test?a=b"
    end

    test "URL with param has replacement" do
      assert Alliance.ToolModel.prepare_url(
               "http://example.org/test?participant=<participantId>",
               %{
                 "participantId" => 123
               }
             ) ==
               "http://example.org/test?participant=123"
    end
  end
end
