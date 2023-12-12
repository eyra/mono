defmodule Systems.Assignment.Assembly do
  alias Core.Repo
  alias Core.Authorization

  alias Systems.{
    Project,
    Assignment,
    Consent,
    Crew,
    Alliance,
    Lab
  }

  def create(template, director, budget \\ nil, auth_node \\ Authorization.prepare_node()) do
    prepare(template, director, budget, auth_node)
    |> Repo.insert()
  end

  def prepare(template, director, budget \\ nil, auth_node \\ Authorization.prepare_node()) do
    crew_auth_node = Authorization.prepare_node(auth_node)
    crew = Crew.Public.prepare(crew_auth_node)
    info = Assignment.Public.prepare_info(info_attrs(template, director))
    page_refs = Assignment.Public.prepare_page_refs(template, auth_node)
    workflow = prepare_workflow(template, auth_node)
    consent_agreement = prepare_consent_agreement(auth_node)

    Assignment.Public.prepare(
      %{special: template},
      crew,
      info,
      page_refs,
      workflow,
      budget,
      consent_agreement,
      auth_node
    )
  end

  defp prepare_workflow(:data_donation, _) do
    Assignment.Public.prepare_workflow(:data_donation, [])
  end

  defp prepare_workflow(:online = template, %Authorization.Node{} = auth_node) do
    tool_auth_node = Authorization.create_node!(auth_node)
    tool = Alliance.Public.prepare_tool(%{director: :assignment}, tool_auth_node)
    prepare_workflow(template, tool)
  end

  defp prepare_workflow(:lab = template, %Authorization.Node{} = auth_node) do
    tool_auth_node = Authorization.create_node!(auth_node)
    tool = Lab.Public.prepare_tool(%{director: :assignment}, tool_auth_node)
    prepare_workflow(template, tool)
  end

  defp prepare_workflow(template, %{} = tool) do
    tool_ref = prepare_tool_ref(template, tool)
    item = Assignment.Public.prepare_workflow_item(tool_ref)
    Assignment.Public.prepare_workflow(template, [item])
  end

  defp prepare_tool_ref(special, tool) do
    field_name = Project.ToolRefModel.tool_field(tool)
    Project.Public.prepare_tool_ref(special, field_name, tool)
  end

  defp prepare_consent_agreement(%Authorization.Node{} = auth_node) do
    agreement_auth_node = Authorization.prepare_node(auth_node)
    Consent.Public.prepare_agreement(agreement_auth_node)
  end

  defp info_attrs(:lab, director) do
    %{
      director: director,
      devices: []
    }
  end

  defp info_attrs(_, director) do
    %{
      director: director,
      devices: [:phone, :tablet, :desktop]
    }
  end
end
