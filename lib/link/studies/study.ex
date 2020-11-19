defmodule Link.Studies.Study do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.Users.User

  # grant_access([:member])

  schema "studies" do
    belongs_to :researcher, User
    field :description, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(study, attrs) do
    study
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
