defmodule Core.Studies.Participant do
  @moduledoc """
  The schema for a study participant.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Studies.Study
  alias Core.Accounts.User

  @primary_key false
  schema "study_participants" do
    belongs_to(:study, Study)
    belongs_to(:user, User)

    field(:status, Ecto.Enum, values: [:applied, :rejected, :entered])

    timestamps()
  end

  @doc false
  def changeset(participant) do
    participant
    |> cast(%{}, [])
  end
end
