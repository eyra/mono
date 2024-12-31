defmodule Systems.Annotation.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Ontology


  schema "annotation" do
    field(:value, :string)
    belongs_to(:term, Ontology.TermModel)
    belongs_to(:user, Account.User)

    timestamps()
  end

  @fields ~w(value)a
  @required_fields ~w(value)a

  def changeset(annotation, attrs) do
    annotation
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: [
    term: preload_graph(:term),
    user: preload_graph(:user)
  ]

  def preload_graph(:term), do: [term: Systems.Ontology.TermModel.preload_graph(:up)]
  def preload_graph(:user), do: [user: Account.User.preload_graph(:up)]
end
