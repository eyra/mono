defmodule Systems.Assignment.Assembly do
  alias Core.Repo
  use Core, :auth

  alias Systems.Assignment
  alias Systems.Consent
  alias Systems.Crew
  alias Systems.Workflow

  def create(template, director, budget \\ nil) do
    prepare(template, director, budget)
    |> Repo.insert()
  end

  def prepare(template, director, budget \\ nil) do
    auth_node = auth_module().create_node!()
    crew_auth_node = auth_module().create_node!(auth_node)
    workflow_auth_node = auth_module().create_node!(crew_auth_node)

    crew = Crew.Public.prepare(crew_auth_node)
    info = Assignment.Public.prepare_info(info_attrs(template, director))
    page_refs = Assignment.Public.prepare_page_refs(template, auth_node)
    workflow = prepare_workflow(template, workflow_auth_node)
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

  defp prepare_workflow(:questionnaire = special, %{} = auth_node) do
    template = Assignment.Private.get_template(special)
    initial_items = prepare_initial_items(template, auth_node)
    prepare_workflow(special, initial_items, auth_node)
  end

  defp prepare_workflow(:data_donation = special, %{} = auth_node) do
    template = Assignment.Private.get_template(special)
    initial_items = prepare_initial_items(template, auth_node)
    prepare_workflow(special, initial_items, auth_node)
  end

  defp prepare_workflow(:benchmark_challenge = special, %{} = auth_node) do
    template = Assignment.Private.get_template(special)
    initial_items = prepare_initial_items(template, auth_node)
    prepare_workflow(special, initial_items, auth_node)
  end

  defp prepare_workflow(:paper_screening = special, %{} = auth_node) do
    template = Assignment.Private.get_template(special)
    initial_items = prepare_initial_items(template, auth_node)
    prepare_workflow(special, initial_items, auth_node)
  end

  defp prepare_workflow(special, initial_items, %{} = auth_node)
       when is_list(initial_items) do
    Assignment.Public.prepare_workflow(special, initial_items, auth_node)
  end

  defp prepare_initial_items(template, auth_node) do
    %{initial_items: initial_items, library: %{items: library_items}} =
      Assignment.Template.workflow_config(template)

    Enum.map(initial_items, fn tool_special ->
      %{type: tool_type} = Enum.find(library_items, &(&1.id == tool_special))
      tool_auth_node = auth_module().create_node!(auth_node)
      tool = Workflow.Public.prepare_tool(tool_type, %{director: :assignment}, tool_auth_node)
      Assignment.Public.prepare_tool_ref(tool_special, tool)
    end)
    |> Assignment.Public.prepare_workflow_items()
  end

  defp prepare_consent_agreement(%{} = auth_node) do
    agreement_auth_node = auth_module().prepare_node(auth_node)
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
