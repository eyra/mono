defmodule Systems.Pool.ParticipantModel do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Accounts.User

  alias Systems.{
    Pool
  }

  @primary_key false
  schema "pool_participants" do
    belongs_to(:user, User)
    belongs_to(:pool, Pool.Model)

    timestamps()
  end

  def changeset(schema, %Pool.Model{} = pool, %User{} = user) do
    schema
    |> change(%{})
    |> Ecto.Changeset.put_assoc(:pool, pool)
    |> Ecto.Changeset.put_assoc(:user, user)
  end
end
