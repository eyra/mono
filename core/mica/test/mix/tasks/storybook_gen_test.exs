defmodule Mix.Tasks.Storybook.GenTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Mix.Tasks.Storybook.Gen

  @moduletag :tmp_dir

  defp gen(dir, opts \\ []) do
    capture_io(fn ->
      Gen.run(["mica/frameworks/pixel", dir, "--prefix", "Frameworks.Pixel"] ++ opts)
    end)
  end

  describe "run/1" do
    test "writes one story per function component, in a flat folder per module", %{tmp_dir: dir} do
      gen(dir)

      assert File.read!(Path.join(dir, "button/dynamic.story.exs")) =~
               "def function, do: &Frameworks.Pixel.Button.dynamic/1"

      assert File.exists?(Path.join(dir, "button.face/label.story.exs"))
    end

    test "skips live components", %{tmp_dir: dir} do
      gen(dir)

      # Frameworks.Pixel.Selector is a live component; its Item submodule has function components.
      refute File.exists?(Path.join(dir, "selector"))
      assert File.exists?(Path.join(dir, "selector.item"))
    end

    test "never touches an existing story", %{tmp_dir: dir} do
      gen(dir)
      path = Path.join(dir, "button/dynamic.story.exs")
      File.write!(path, "curated")

      assert gen(dir) =~ "Wrote 0 stories"
      assert File.read!(path) == "curated"
    end
  end

  describe "run/1 with --check" do
    test "fails and lists the components without a story", %{tmp_dir: dir} do
      error = assert_raise Mix.Error, fn -> gen(dir, ["--check"]) end

      assert error.message =~ Path.join(dir, "button/dynamic.story.exs")
      refute File.exists?(Path.join(dir, "button"))
    end

    test "passes once every component has a story", %{tmp_dir: dir} do
      gen(dir)

      assert gen(dir, ["--check"]) == ""
    end
  end
end
