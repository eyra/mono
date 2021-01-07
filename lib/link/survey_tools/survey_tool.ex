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

    field :survey_url, :string

    has_many :tasks, SurveyToolTask

    timestamps()
  end

  @doc false
  def changeset(survey_tool, attrs) do
    survey_tool
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
