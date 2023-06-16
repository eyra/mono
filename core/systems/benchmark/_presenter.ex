defmodule Systems.Benchmark.Presenter do
  use Systems.Presenter

  alias Systems.{
    Benchmark
  }

  @impl true
  def view_model(id, Benchmark.ToolPage = page, assigns) when is_number(id) do
    Benchmark.Public.get_tool!(id, Benchmark.ToolModel.preload_graph(:down))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(%Benchmark.ToolModel{} = tool, page, assigns) do
    builder(page).view_model(tool, assigns)
  end

  defp builder(Benchmark.ToolPage), do: Benchmark.ToolPageBuilder
end
