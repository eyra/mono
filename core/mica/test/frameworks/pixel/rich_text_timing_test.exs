defmodule Frameworks.Pixel.RichTextTimingTest do
  # Not async, so other tests don't eat into the time budget.
  use ExUnit.Case, async: false

  alias Frameworks.Pixel.RichText

  # Cleaning these inputs takes well under a second. A cleaner that is
  # quadratic in them needs minutes, so the budget leaves room for a busy
  # machine and still tells the two apart.
  @budget 10_000

  describe "clean/1 takes linear time" do
    test "on a long run of &" do
      assert within_budget(fn -> RichText.clean(String.duplicate("&", 200_000)) end) ==
               String.duplicate("&amp;", 200_000)
    end

    test "on a long run of &#" do
      assert within_budget(fn -> RichText.clean(String.duplicate("&#", 100_000)) end) ==
               String.duplicate("&amp;#", 100_000)
    end

    test "on a long run of & followed by a letter" do
      assert within_budget(fn -> RichText.clean(String.duplicate("&a", 100_000)) end) ==
               String.duplicate("&amp;a", 100_000)
    end
  end

  describe "clean/1 takes linear time on spaces inside an address" do
    @tag :address_space_regression
    test "in href" do
      address = "x" <> String.duplicate(" ", 1_900_000) <> "x"
      html = ~s|<a href="#{address}">link</a>|

      assert within_budget(fn -> RichText.clean(html) end) ==
               ~s|<a href="#{address}" target="_blank">link</a>|
    end

    @tag :address_space_regression
    test "in src" do
      address = "x" <> String.duplicate(" ", 1_900_000) <> "x"
      html = ~s|<img src="#{address}">|

      assert within_budget(fn -> RichText.clean(html) end) == ~s|<img src="#{address}" />|
    end
  end

  # Each end tag that closes no open element made the parser search every
  # open element: minutes for these inputs.
  describe "clean/1 takes linear time on end tags that close nothing" do
    test "after deeply nested elements" do
      html = String.duplicate("<div>", 66_000) <> String.duplicate("</span>", 66_000)

      assert within_budget(fn -> RichText.clean(html) end) ==
               String.duplicate("<div>", 66_000) <> String.duplicate("</div>", 66_000)
    end

    test "with only tags the editor makes" do
      html = String.duplicate("<span>", 61_000) <> String.duplicate("</b>", 61_000)

      assert within_budget(fn -> RichText.clean(html) end) ==
               String.duplicate("<span>", 61_000) <> String.duplicate("</span>", 61_000)
    end

    test "of an element that has no end tag" do
      html = String.duplicate("<div>", 66_000) <> String.duplicate("</img>", 66_000)

      assert within_budget(fn -> RichText.clean(html) end) ==
               String.duplicate("<div>", 66_000) <> String.duplicate("</div>", 66_000)
    end
  end

  describe "clean/1 takes linear time on deep nesting" do
    test "of elements that are kept" do
      html = String.duplicate("<div>", 160_000) <> "x" <> String.duplicate("</div>", 160_000)
      assert within_budget(fn -> RichText.clean(html) end) == html
    end

    test "of elements that are removed" do
      html = String.duplicate("<font>", 130_000) <> "x"
      assert within_budget(fn -> RichText.clean(html) end) == "x"
    end
  end

  defp within_budget(fun) do
    task = Task.async(fun)

    case Task.yield(task, @budget) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> flunk("took longer than #{@budget} ms")
    end
  end
end
