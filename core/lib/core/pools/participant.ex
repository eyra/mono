defmodule Core.Pools.Participant do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Ecto.Schema

  alias Core.Accounts.User

  schema "pool_participants" do
    belongs_to(:user, User)
    belongs_to(:pool, Pool)

    timestamps()
  end
end
