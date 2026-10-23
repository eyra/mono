defmodule Mix.Tasks.Storybook.Gen do
  @shortdoc "Writes a storybook story for every function component without one"
  @moduledoc """
  Writes a `*.story.exs` for every public function component (`def` with `attr`/`slot`
  declarations) defined under SOURCE_DIR that has no story in CONTENT_DIR yet. Existing stories are
  never touched, so curate a story by editing its generated file.

      mix storybook.gen SOURCE_DIR CONTENT_DIR [--prefix MODULE] [--check]

  Each module gets one folder named after it, minus `--prefix`, with a story per component:
  with `--prefix Frameworks.Pixel`, `Frameworks.Pixel.Button.dynamic/1` becomes
  `CONTENT_DIR/button/dynamic.story.exs` and `Frameworks.Pixel.Button.Face.label/1`
  becomes `CONTENT_DIR/button.face/label.story.exs`. The folders stay flat, so a function never
  shares its storybook path with a nested module of the same name.

  The `:default` variation fills required attributes from their `examples:` or `values:`, or with
  a placeholder for their type, and gives the default slot some text.

  `--check` writes nothing and fails when a story is missing.

  LiveViews and live components are skipped: their components render with the state of the
  process, so a story for them is written by hand (`use PhoenixStorybook.Story, :live_component`).
  """
  use Mix.Task

  @requirements ["compile"]

  @impl Mix.Task
  def run(args) do
    {opts, [source_dir, content_dir]} =
      OptionParser.parse!(args, strict: [check: :boolean, prefix: :string])

    prefix = opts |> Keyword.get(:prefix, "") |> String.split(".", trim: true)

    missing =
      source_dir
      |> components(prefix)
      |> Enum.map(fn {path, story} -> {Path.join(content_dir, path), story} end)
      |> Enum.reject(fn {file, _story} -> File.exists?(file) end)

    if opts[:check], do: check(missing), else: write(missing)

    Mix.Task.reenable("storybook.gen")
  end

  defp check([]), do: :ok

  defp check(missing) do
    files = Enum.map_join(missing, "\n", fn {file, _} -> "  #{file}" end)
    Mix.raise("Components without a story (run mix storybook.stories):\n#{files}")
  end

  defp write(missing) do
    for {file, story} <- missing do
      File.mkdir_p!(Path.dirname(file))
      File.write!(file, story)
    end

    Mix.shell().info("Wrote #{length(missing)} stories")
  end

  defp components(source_dir, prefix) do
    source_dir = Path.expand(source_dir) <> "/"

    for module <- modules(source_dir),
        {fun, %{kind: :def} = component} <- module.__components__() do
      name = fun |> Atom.to_string() |> String.replace(~r/[?!]/, "")

      {Path.join(folder(module, prefix), "#{name}.story.exs"),
       story(module, fun, name, component)}
    end
  end

  defp folder(module, prefix) do
    split = Module.split(module)
    split = if List.starts_with?(split, prefix), do: Enum.drop(split, length(prefix)), else: split
    Enum.map_join(split, ".", &Macro.underscore/1)
  end

  defp modules(source_dir) do
    {:ok, modules} = :application.get_key(Core.Env.app(), :modules)

    Enum.filter(modules, fn module ->
      Code.ensure_loaded!(module)

      function_exported?(module, :__components__, 0) and
        not function_exported?(module, :__live__, 0) and
        module.module_info(:compile)[:source] |> to_string() |> String.starts_with?(source_dir)
    end)
  end

  defp story(module, fun, name, %{attrs: attrs, slots: slots}) do
    story_module = Module.concat([Storybook | Module.split(module)] ++ [Macro.camelize(name)])

    attributes =
      for %{required: true, name: attr, type: type, opts: opts} <- attrs, into: %{} do
        {attr, example(type, opts)}
      end

    """
    defmodule #{inspect(story_module)} do
      use PhoenixStorybook.Story, :component

      def function, do: &#{inspect(module)}.#{fun}/1

      def variations do
        [
          %Variation{
            id: :default,
            attributes: #{inspect(attributes, limit: :infinity)},
            slots: #{inspect(slot_examples(slots))}
          }
        ]
      end
    end
    """
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  defp example(type, opts), do: first_or(opts[:examples] || opts[:values], type)

  defp first_or([value | _], _type), do: value
  defp first_or(_, type), do: placeholder(type)

  defp placeholder(:string), do: "Lorem ipsum"
  defp placeholder(:boolean), do: false
  defp placeholder(:integer), do: 1
  defp placeholder(:float), do: 1.0
  defp placeholder(:list), do: []
  defp placeholder(:map), do: %{}
  defp placeholder(_), do: nil

  defp slot_examples(slots) do
    for %{name: slot, required: required} <- slots, slot == :inner_block or required do
      if slot == :inner_block, do: "Lorem ipsum", else: "<:#{slot}>Lorem ipsum</:#{slot}>"
    end
  end
end
