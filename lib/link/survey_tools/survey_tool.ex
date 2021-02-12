defmodule Link.SurveyTools.SurveyTool do
  @moduledoc """
  The survey tool schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.Studies.Study
  alias Link.SurveyTools.SurveyToolTask
  alias Link.Users.User

  schema "survey_tools" do
    belongs_to :auth_node, Link.Authorization.Node
    belongs_to :study, Study

    field :title, :string
    field :description, :string
    field :survey_url, :string
    field :subject_count, :integer
    field :phone_enabled, :boolean
    field :tablet_enabled, :boolean
    field :desktop_enabled, :boolean

    has_many :tasks, SurveyToolTask
    many_to_many :participants, User, join_through: :survey_tool_participants

    timestamps()
  end

  defimpl GreenLight.AuthorizationNode do
    def id(survey_tool), do: survey_tool.auth_node_id
  end

  @doc false
  def changeset(survey_tool, attrs) do
    survey_tool
    |> cast(attrs, [
      :title,
      :description,
      :survey_url,
      :subject_count,
      :phone_enabled,
      :tablet_enabled,
      :desktop_enabled
    ])
    |> validate_required([:title])
  end
end
