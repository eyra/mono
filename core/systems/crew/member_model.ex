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

    belongs_to(:crew, Crew.Model)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(member, attrs \\ %{}) do
    member
    |> cast(attrs, [:public_id, :expire_at, :expired])
  end
end
