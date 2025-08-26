defmodule Systems.Advert.Model do
  @moduledoc """
  The advert type.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  use Gettext, backend: CoreWeb.Gettext
  import Ecto.Changeset

  alias Frameworks.Concept

  alias Systems.Advert
  alias Systems.Promotion
  alias Systems.Assignment
  alias Systems.Pool

  schema "adverts" do
    field(:status, Ecto.Enum, values: Concept.Leaf.Status.values(), default: :concept)
    belongs_to(:assignment, Assignment.Model)
    belongs_to(:promotion, Promotion.Model)
    belongs_to(:submission, Pool.SubmissionModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(status)a
  @required_fields @fields

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(advert), do: advert.auth_node_id
  end

  defimpl Frameworks.Concept.Leaf do
    use Gettext, backend: CoreWeb.Gettext

    def tag(_), do: dgettext("eyra-advert", "leaf.tag")
    def resource_id(%{id: id}), do: "advert/#{id}"

    def info(%{submission: %{pool: %{name: pool_name}}}, _timezone) do
      [pool_name]
    end

    def status(%{status: status}), do: %Concept.Leaf.Status{value: status}
  end

  @doc false
  def changeset(advert, attrs) do
    cast(advert, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:assignment, :promotion, :submission, :auth_node])

  def preload_graph(:assignment), do: [assignment: Assignment.Model.preload_graph(:down)]
  def preload_graph(:promotion), do: [promotion: Promotion.Model.preload_graph(:down)]
  def preload_graph(:submission), do: [submission: Pool.SubmissionModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: [:role_assignments]]

  def auth_tree(%Advert.Model{auth_node: auth_node}), do: auth_node
end
