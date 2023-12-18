defmodule Systems.Crew.MemberModel do
  @moduledoc """
  The schema for a participant.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Systems.Crew
  alias Core.Accounts.User

  schema "crew_members" do
    field(:public_id, :integer)
    field(:expire_at, :naive_datetime)
    field(:expired, :boolean)
    field(:declined_at, :naive_datetime)
    field(:declined, :boolean)

    belongs_to(:crew, Crew.Model)
    belongs_to(:user, User)

    timestamps()
  end

  @fields ~w(public_id expire_at expired declined_at declined)a

  @doc false
  def changeset(member, attrs \\ %{}) do
    member
    |> cast(attrs, @fields)
  end

  def reset_attrs(expire_at) do
    [
      expired: false,
      expire_at: expire_at
    ]
  end
end
