defmodule Systems.Instruction.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Instruction

  @impl true
  def intercept(
        {:content_page, _} = signal,
        %{content_page: content_page} = message
      ) do
    if tool =
         Instruction.Public.get_tool_by(
           content_page,
           Instruction.ToolModel.preload_graph(:down)
         ) do
      dispatch!(
        {:instruction_tool, signal},
        Map.merge(message, %{instruction_tool: tool})
      )
    end

    :ok
  end

  @impl true
  def intercept(
        {:content_repository, _} = signal,
        %{content_repository: content_repository} = message
      ) do
    if asset =
         Instruction.Public.get_asset_by(
           content_repository,
           Instruction.AssetModel.preload_graph(:down)
         ) do
      dispatch!(
        {:instruction_asset, signal},
        Map.merge(message, %{instruction_asset: asset})
      )
    end

    :ok
  end

  @impl true
  def intercept(
        {:instruction_asset, _} = signal,
        %{instruction_asset: %{tool_id: tool_id}} = message
      ) do
    tool = Instruction.Public.get_tool!(tool_id, Instruction.ToolModel.preload_graph(:down))

    dispatch!(
      {:instruction_tool, signal},
      Map.merge(message, %{instruction_tool: tool})
    )

    :ok
  end
end
