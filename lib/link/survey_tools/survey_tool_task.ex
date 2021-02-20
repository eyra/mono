defmodule Link.SurveyTools.SurveyToolTask do
  @moduledoc """
  A task (fill out survey) to be completed by a participant.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Link.SurveyTools.SurveyTool
  alias Link.Accounts.User

  schema "survey_tool_tasks" do
    belongs_to :survey_tool, SurveyTool
    belongs_to :user, User
    field :status, Ecto.Enum, values: [:pending, :completed]

    timestamps()
  end

  @doc false
  def changeset(survey_tool_task, attrs) do
    survey_tool_task
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
