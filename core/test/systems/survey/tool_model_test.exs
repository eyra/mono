defmodule Systems.Survey.ToolModelTest do
  use Core.DataCase, async: true

  alias Systems.{
    Survey
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
          Survey.ToolModel.changeset(%Survey.ToolModel{}, :auto_save, %{survey_url: unquote(url)})

        assert changeset.valid?, changeset.errors
      end
    end

    for url <- [
          "http://example.org/survey?a=<param",
          "http://example.org/survey?b=<var with space>",
          "http://example.org/survey?c=<var-with-dash>",
          "http://example.org/survey?d=<unclosed&other=<var>"
        ] do
      test "disallow URL: #{url}" do
        changeset =
          Survey.ToolModel.changeset(%Survey.ToolModel{}, :auto_save, %{survey_url: unquote(url)})

        refute changeset.valid?
      end
    end
  end

  describe "prepare_survey_url" do
    test "URL without params stays the same" do
      assert Survey.ToolModel.prepare_url("http://example.org/test?a=b", %{}) ==
               "http://example.org/test?a=b"
    end

    test "URL with param has replacement" do
      assert Survey.ToolModel.prepare_url(
               "http://example.org/test?participant=<participantId>",
               %{
                 "participantId" => 123
               }
             ) ==
               "http://example.org/test?participant=123"
    end
  end
end
