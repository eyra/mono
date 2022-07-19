defmodule Systems.Pool.ParticipantModel do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Ecto.Schema

  alias Core.Accounts.User

  alias Systems.{
    Pool
  }

  schema "pool_participants" do
    belongs_to(:user, User)
    belongs_to(:pool, Pool.Model)

    timestamps()
  end
end
