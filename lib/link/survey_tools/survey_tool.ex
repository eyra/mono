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
    field :duration, :string
    field :phone_enabled, :boolean
    field :tablet_enabled, :boolean
    field :desktop_enabled, :boolean
    field :is_published, :boolean
    field :published_at, :naive_datetime

    has_many :tasks, SurveyToolTask

    timestamps()
  end

  @fields ~w(title description survey_url subject_count duration phone_enabled tablet_enabled desktop_enabled is_published published_at)a

  @doc false
  def changeset(survey_tool, attrs) do
    survey_tool
    |> cast(attrs, @fields)
    |> validate_required([:title])
  end
end
