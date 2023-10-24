defmodule Systems.Consent.RevisionModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Consent
  }

  schema "consent_revisions" do
    field(:source, :string)
    belongs_to(:agreement, Consent.AgreementModel)
    has_many(:signatures, Consent.SignatureModel, foreign_key: :revision_id)
    timestamps()
  end

  @fields ~w(source)a
  @required_fields ~w()a

  def preload_graph(:up), do: preload_graph([:agreement])
  def preload_graph(:down), do: preload_graph([:signatures])

  def preload_graph(:agreement), do: [agreement: Consent.AgreementModel.preload_graph(:up)]
  def preload_graph(:signatures), do: [signatures: Consent.SignatureModel.preload_graph(:down)]

  def changeset(revision, attrs) do
    revision
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

end
