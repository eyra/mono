defmodule Systems.Project.ContentPageBuilder.Item do
  def view_model(item, assigns) do
    get_builder(item).view_model(item, assigns)
  end

  defp get_builder(%{tool_ref: %{data_donation_tool: tool}}) when not is_nil(tool) do
    Systems.Project.ContentPageBuilder.ItemDataDonation
  end

  defp get_builder(%{tool_ref: %{benchmark_tool: tool}}) when not is_nil(tool) do
    Systems.Project.ContentPageBuilder.ItemBenchmark
  end

  defp get_builder(item) do
    raise "Unsupported item: #{item}"
  end
end
