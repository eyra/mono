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

    belongs_to :auth_node, Link.Authorization.Node

    has_many :role_assignments, through: [:auth_node, :role_assignments]

    has_many :authors, Link.Studies.Author
    has_many :participants, Link.Studies.Participant
    has_many :survey_tools, Link.SurveyTools.SurveyTool

    timestamps()
  end

  @required_fields ~w(title)a
  @optional_fields ~w(description)a
  @fields @required_fields ++ @optional_fields

  defimpl GreenLight.AuthorizationNode do
    def id(study), do: study.auth_node_id
  end

  @doc false
  def changeset(study, attrs) do
    study
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
