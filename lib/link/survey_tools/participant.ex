defmodule Link.SurveyTools.Participant do
  @moduledoc """
  The schema for a study participant.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Link.SurveyTools.SurveyTool
  alias Link.Accounts.User

  @primary_key false
  schema "survey_tool_participants" do
    belongs_to :survey_tool, SurveyTool
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(participant) do
    participant
    |> cast(%{}, [])
  end
end
