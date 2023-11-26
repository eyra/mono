defmodule Systems.Benchmark.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Benchmark
  }

  @impl true
  def view_model(page, %Benchmark.ToolModel{} = tool, assigns) do
    builder(page).view_model(tool, assigns)
  end

  defp builder(Benchmark.ToolPage), do: Benchmark.ToolPageBuilder
end
