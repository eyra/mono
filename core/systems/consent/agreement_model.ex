defmodule Systems.Consent.AgreementModel do
  @moduledoc false
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Consent

  schema "consent_agreements" do
    belongs_to(:auth_node, Core.Authorization.Node)
    has_many(:revisions, Consent.RevisionModel, foreign_key: :agreement_id)
    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a

  def preload_graph(:down), do: preload_graph([:auth_node])
  def preload_graph(:up), do: preload_graph([])
  def preload_graph(:revisions), do: [revisions: Consent.RevisionModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]

  def changeset(agreement, attrs \\ %{}) do
    cast(agreement, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end
end
