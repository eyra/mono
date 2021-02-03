defmodule Link.SurveyTools.SurveyTool do
  @moduledoc """
  The survey tool schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.Studies.Study
  alias Link.SurveyTools.SurveyToolTask

  schema "survey_tools" do
    belongs_to :study, Study

    field :title, :string
    field :description, :string
    field :survey_url, :string
    field :subject_count, :integer
    field :phone_enabled, :boolean
    field :tablet_enabled, :boolean
    field :desktop_enabled, :boolean

    has_many :tasks, SurveyToolTask

    timestamps()
  end

  @doc false
  def changeset(survey_tool, attrs) do
    survey_tool
    |> cast(attrs, [:title, :description, :survey_url, :subject_count, :phone_enabled, :tablet_enabled, :desktop_enabled])
    |> validate_required([:title])
  end
end
