defmodule Link.Studies.Study do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  # grant_access([:member])

  schema "studies" do
    field :description, :string
    field :title, :string

    has_many :role_assignments, Link.Users.RoleAssignment,
      foreign_key: :entity_id,
      defaults: [entity_type: Link.Studies.Study |> Atom.to_string()]

    has_many :participants, Link.Studies.Participant

    timestamps()
  end

  @doc false
  def changeset(study, attrs) do
    study
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end
end
