defmodule Systems.Assignment.Model do
  @moduledoc """
  The assignment type.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Budget
  alias Systems.Content
  alias Systems.Consent
  alias Systems.Storage

  schema "assignments" do
    field(:special, Ecto.Atom)
    field(:status, Ecto.Enum, values: Assignment.Status.values(), default: :concept)
    field(:external_panel, Ecto.Enum, values: Assignment.ExternalPanelIds.values())

    belongs_to(:info, Assignment.InfoModel)
    belongs_to(:privacy_doc, Content.FileModel, on_replace: :nilify)
    belongs_to(:consent_agreement, Consent.AgreementModel, on_replace: :update)
    belongs_to(:storage_endpoint, Storage.EndpointModel, on_replace: :delete)
    belongs_to(:workflow, Workflow.Model)
    belongs_to(:crew, Systems.Crew.Model)
    belongs_to(:budget, Budget.Model, on_replace: :update)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_one(:project_item, Project.ItemModel, foreign_key: :assignment_id)
    has_many(:page_refs, Assignment.PageRefModel, foreign_key: :assignment_id)

    many_to_many(
      :excluded,
      Assignment.Model,
      join_through: Assignment.ExcludeModel,
      join_keys: [to_id: :id, from_id: :id],
      on_replace: :delete
    )

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w(special status external_panel)a

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(assignment), do: assignment.auth_node_id
  end

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Concept.System.director(director)
  end

  def auth_tree(%Assignment.Model{auth_node: auth_node}), do: auth_node

  def changeset(assignment, nil), do: changeset(assignment, %{})

  def changeset(assignment, %Budget.Model{id: budget_id}) do
    assignment
    |> cast(%{budget_id: budget_id}, [:budget_id])
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:director])
    |> cast(attrs, @fields)
  end

  def flatten(assignment) do
    assignment
    |> Map.take([
      :id,
      :consent_agreement,
      :info,
      :page_refs,
      :storage_endpoint,
      :workflow,
      :crew,
      :budget,
      :excluded,
      :director
    ])
    |> Map.put(:tool, tool(assignment))
  end

  def language(%Assignment.Model{info: info}), do: language(info)
  def language(%Assignment.InfoModel{language: language}), do: language(language)
  def language(nil), do: Assignment.Languages.default()

  def language(language) do
    if Enum.member?(Assignment.Languages.values(), language) do
      language
    else
      Assignment.Languages.default()
    end
  end

  def tool(%{workflow: workflow}) when not is_nil(workflow) do
    [tool | _] = Workflow.Model.flatten(workflow)
    tool
  end

  def tool(_), do: nil

  def tag(%{special: special}) do
    Assignment.Templates.translate(special)
  end

  def preload_graph(:down) do
    [
      :excluded,
      info: [],
      page_refs: [:page],
      privacy_doc: [],
      consent_agreement: [:revisions],
      storage_endpoint: Storage.EndpointModel.preload_graph(:down),
      crew: [:tasks, :members, :auth_node],
      workflow: Workflow.Model.preload_graph(:down),
      budget: [:currency, :fund, :reserve],
      auth_node: [:role_assignments]
    ]
  end

  def preload_graph(_), do: []
end
