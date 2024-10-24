defmodule Frameworks.Pixel.TrixPostProcessorTest do
  use ExUnit.Case
  alias Frameworks.Pixel.TrixPostProcessor

  describe "add_target_blank/1" do
    test "adds target=_blank to <a> tags without target attribute" do
      html_content = "<a href=\"http://example.com\">Example</a>"
      expected = "<a href=\"http://example.com\" target=\"_blank\">Example</a>"
      assert TrixPostProcessor.add_target_blank(html_content) == expected
    end

    test "does not modify <a> tags with existing target attribute" do
      html_content = "<a href=\"http://example.com\" target=\"_self\">Example</a>"
      expected = "<a href=\"http://example.com\" target=\"_self\">Example</a>"
      assert TrixPostProcessor.add_target_blank(html_content) == expected
    end

    test "adds target=_blank to multiple <a> tags without target attribute" do
      html_content =
        "<a href=\"http://example1.com\">Example1</a> <a href=\"http://example2.com\">Example2</a>"

      expected =
        "<a href=\"http://example1.com\" target=\"_blank\">Example1</a> <a href=\"http://example2.com\" target=\"_blank\">Example2</a>"

      assert TrixPostProcessor.add_target_blank(html_content) == expected
    end

    test "handles nested <a> tags correctly" do
      html_content = "<div><a href=\"http://example.com\">Example</a></div>"
      expected = "<div><a href=\"http://example.com\" target=\"_blank\">Example</a></div>"
      assert TrixPostProcessor.add_target_blank(html_content) == expected
    end

    test "returns the same content if no <a> tags are present" do
      html_content = "<p>No links here</p>"
      expected = "<p>No links here</p>"
      assert TrixPostProcessor.add_target_blank(html_content) == expected
    end
  end
end
