defmodule Systems.Assignment.Private do
  use CoreWeb, :verified_routes

  require Logger

  alias Systems.{
    Assignment,
    Workflow,
    Crew,
    Storage
  }

  def allowed_external_panel_ids() do
    Keyword.get(config(), :external_panels, [])
  end

  defp config() do
    Application.get_env(:core, :assignment)
  end

  def panel_function_component(%Assignment.Model{external_panel: nil}), do: nil

  def panel_function_component(%Assignment.Model{external_panel: :liss}),
    do: &Assignment.PanelViews.liss/1

  def panel_function_component(%Assignment.Model{external_panel: _}),
    do: &Assignment.PanelViews.default/1

  def connector_popup_module(:storage), do: Assignment.ConnectorPopupStorage
  def connector_popup_module(:panel), do: Assignment.ConnectorPopupPanel

  def connection_view_module(:storage), do: Assignment.ConnectionViewStorage
  def connection_view_module(:panel), do: Assignment.ConnectionViewPanel

  def connection_title(:storage, %{storage_endpoint: storage_endpoint}),
    do: connection_title(:storage, Storage.EndpointModel.special_field(storage_endpoint))

  def connection_title(:storage, storage_service_id),
    do: Storage.ServiceIds.translate(storage_service_id)

  def connection_title(:panel, %{external_panel: external_panel}),
    do: Assignment.ExternalPanelIds.translate(external_panel)

  def task_template(%{special: :data_donation}, %Workflow.ItemModel{id: item_id}) do
    ["item=#{item_id}"]
  end

  def task_identifier(
        %{special: :data_donation},
        %Workflow.ItemModel{id: item_id},
        %Crew.MemberModel{id: member_id}
      ) do
    ["item=#{item_id}", "member=#{member_id}"]
  end

  # Depricated
  def task_identifier(tool, user) do
    Logger.warn(
      "`Systems.Assignment.Private.task_identifier/2` is deprecated; call `task_identifier/3` instead."
    )

    [
      Atom.to_string(Frameworks.Concept.ToolModel.key(tool)),
      Integer.to_string(tool.id),
      Integer.to_string(user.id)
    ]
  end
end
