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

  defp within_budget(fun) do
    task = Task.async(fun)

    case Task.yield(task, @budget) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> flunk("took longer than #{@budget} ms")
    end
  end
end
