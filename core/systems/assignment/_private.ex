defmodule Systems.Assignment.Private do
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  require Logger

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Frameworks.Utility.Identifier

  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Crew
  alias Systems.Storage
  alias Systems.Monitor

  def ensure_affiliate!(%Assignment.Model{} = assignment) do
    {:ok, %{assignment: assignment}} = ensure_affiliate(assignment)
    assignment
  end

  def ensure_affiliate(%Assignment.Model{affiliate: nil} = assignment) do
    Multi.new()
    |> Multi.insert(:affiliate, Affiliate.Public.prepare_affiliate())
    |> Multi.update(:assignment, fn %{affiliate: affiliate} ->
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:affiliate, affiliate)
    end)
    |> Signal.Public.multi_dispatch({:affiliate, :inserted})
    |> Repo.transaction()
  end

  def ensure_affiliate(%Assignment.Model{} = assignment), do: {:ok, %{assignment: assignment}}

  def get_template(%Assignment.Model{special: special}), do: get_template(special)

  def get_template(:data_donation), do: %Assignment.TemplateDataDonation{id: :data_donation}

  def get_template(:benchmark_challenge),
    do: %Assignment.TemplateBenchmarkChallenge{id: :benchmark_challenge}

  def get_template(:paper_screening),
    do: %Assignment.TemplatePaperScreening{id: :paper_screening}

  def get_template(:questionnaire),
    do: %Assignment.TemplateQuestionnaire{id: :questionnaire}

  def declined_consent?(assignment, user_ref) do
    Monitor.Public.event({assignment, :declined, user_ref})
    |> Monitor.Public.exists?()
  end

  def log_performance_event(
        %Assignment.Model{} = assignment,
        %Crew.TaskModel{} = crew_task,
        topic
      ) do
    with {:ok, workflow_item} <- get_workflow_item(crew_task),
         {:ok, user_ref} <- get_crew_member(crew_task),
         false <- Assignment.Public.tester?(assignment, user_ref) do
      log_performance_event(assignment, {workflow_item, topic, user_ref})
    end
  end

  def log_performance_event(%Assignment.Model{} = assignment, topic, user_ref) do
    if not Assignment.Public.tester?(assignment, user_ref) do
      log_performance_event(assignment, {assignment, topic, user_ref})
    end
  end

  def log_performance_event(%Assignment.Model{} = assignment, event) do
    Multi.new()
    |> Monitor.Public.multi_log(event)
    |> Signal.Public.multi_dispatch({:assignment, :monitor_event}, %{
      assignment: assignment,
      monitor_event: event
    })
    |> Repo.transaction()
  end

  def clear_performance_event(%Assignment.Model{} = assignment, topic, user_ref) do
    Monitor.Public.event({assignment, topic, user_ref})
    |> Monitor.Public.clear()
  end

  def storage_endpoint_key(%Assignment.Model{id: id}) do
    "assignment=#{id}"
  end

  def get_preview_url(%Assignment.Model{id: id, external_panel: external_panel}) do
    case external_panel do
      :liss ->
        ~p"/assignment/#{id}/liss?respondent=preview&quest=quest&varname1=varname1&token=token&page=page"

      :ioresearch ->
        ~p"/assignment/#{id}/ioresearch?participant=preview"

      _ ->
        ~p"/assignment/#{id}/participate?participant=preview"
    end
  end

  def page_title_default(:assignment_information),
    do: dgettext("eyra-assignment", "intro.page.title")

  def page_title_default(:assignment_helpdesk),
    do: dgettext("eyra-assignment", "support.page.title")

  def page_body_default(:assignment_information), do: ""
  def page_body_default(:assignment_helpdesk), do: ""

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
        assignment,
        workflow_item,
        %Crew.MemberModel{id: member_id}
      ) do
    task_identifier(assignment, workflow_item, member_id)
  end

  def task_identifier(
        %{special: :data_donation},
        %Workflow.ItemModel{id: item_id},
        member_id
      ) do
    ["item=#{item_id}", "member=#{member_id}"]
  end

  def task_identifier(
        %{special: :benchmark_challenge},
        %Workflow.ItemModel{id: item_id},
        member_id
      ) do
    ["item=#{item_id}", "member=#{member_id}"]
  end

  def task_identifier(
        %{special: :questionnaire},
        %Workflow.ItemModel{id: item_id},
        member_id
      ) do
    ["item=#{item_id}", "member=#{member_id}"]
  end
end
