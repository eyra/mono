defmodule Systems.Assignment.Private do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  require Logger

  alias Frameworks.Utility.Identifier

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Crew
  alias Systems.Storage
  alias Systems.Monitor

  def log_performance_event(
        %Assignment.Model{} = assignment,
        %Crew.TaskModel{} = crew_task,
        topic
      ) do
    with {:ok, workflow_item} <- get_workflow_item(crew_task),
         {:ok, user_ref} <- get_crew_member(crew_task),
         false <- Assignment.Public.tester?(assignment, user_ref) do
      Monitor.Public.log(workflow_item, topic, user_ref)
    end
  end

  def log_performance_event(%Assignment.Model{} = assignment, topic, user_ref) do
    if not Assignment.Public.tester?(assignment, user_ref) do
      Monitor.Public.log(assignment, topic, user_ref)
    end
  end

  def clear_performance_event(%Assignment.Model{} = assignment, topic, user_ref) do
    Monitor.Public.event(assignment, topic, user_ref)
    |> Monitor.Public.clear()
  end

  def storage_endpoint_key(%Assignment.Model{id: id}) do
    "assignment=#{id}"
  end

  def get_panel_url(%Assignment.Model{id: id, external_panel: external_panel}) do
    case external_panel do
      :liss -> ~p"/assignment/#{id}/liss"
      :ioresearch -> ~p"/assignment/#{id}/ioresearch?participant={id}&language=nl"
      :generic -> ~p"/assignment/#{id}/participate?participant={id}&language=nl"
    end
  end

  def get_preview_url(%Assignment.Model{id: id, external_panel: external_panel}, participant) do
    case external_panel do
      :liss ->
        ~p"/assignment/#{id}/liss?respondent=#{participant}&quest=quest&varname1=varname1&token=token&page=page"

      :ioresearch ->
        ~p"/assignment/#{id}/ioresearch?participant=#{participant}"

      _ ->
        ~p"/assignment/#{id}/participate?participant=#{participant}"
    end
  end

  def page_title_default(:assignment_intro), do: dgettext("eyra-assignment", "intro.page.title")

  def page_title_default(:assignment_support),
    do: dgettext("eyra-assignment", "support.page.title")

  def page_body_default(:assignment_intro), do: ""
  def page_body_default(:assignment_support), do: ""

  def allowed_external_panel_ids() do
    Keyword.get(config(), :external_panels, [])
  end

  defp config() do
    Application.get_env(:core, :assignment)
  end

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

  # Crew Task & Workflow Item mapping

  def get_workflow_item(%Crew.TaskModel{} = task, preload \\ []) do
    if item_id = workflow_item_id(task) do
      {:ok,
       item_id
       |> String.to_integer()
       |> Workflow.Public.get_item!(preload)}
    else
      {:error, nil}
    end
  end

  def get_crew_member(%Crew.TaskModel{} = task, preload \\ []) do
    if member_id = member_id(task) do
      {:ok,
       member_id
       |> String.to_integer()
       |> Crew.Public.get_member!(preload)}
    else
      {:error, nil}
    end
  end

  def member_id(%Crew.TaskModel{identifier: identifier}),
    do: Identifier.get_attribute(identifier, "member")

  def workflow_item_id(%Crew.TaskModel{identifier: identifier}),
    do: Identifier.get_attribute(identifier, "item")

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

  # Deprecated
  def task_identifier(_tool, _user) do
    raise RuntimeError,
          "`Systems.Assignment.Private.task_identifier/2` is deprecated; call `task_identifier/3` instead."
  end
end
