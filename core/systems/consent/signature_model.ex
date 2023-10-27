defmodule Systems.Consent.SignatureModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Consent
  }

  schema "consent_signatures" do
    belongs_to(:revision, Consent.RevisionModel)
    belongs_to(:user, Core.Accounts.User)
    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a

  def preload_graph(:up), do: preload_graph([:revision])
  def preload_graph(:down), do: preload_graph([:user])

  def preload_graph(:revision), do: [revision: Consent.RevisionModel.preload_graph(:up)]
  def preload_graph(:user), do: [user: []]

  def changeset(signature, attrs \\ %{}) do
    signature
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end
end
