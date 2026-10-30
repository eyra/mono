defmodule Systems.Announcement.RecipientModel do
  @moduledoc """
  One user who received an announcement. `read_at` is set the first time the
  user opens it.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account.User
  alias Systems.Announcement

  schema "announcement_recipient" do
    field(:read_at, :utc_datetime)

    belongs_to(:announcement, Announcement.Model)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(recipient, attrs) do
    recipient
    |> cast(attrs, [:read_at])
    |> validate_required([:announcement_id, :user_id])
    |> unique_constraint([:announcement_id, :user_id])
  end

  def preload_graph(:down), do: preload_graph([:announcement])
  def preload_graph(:announcement), do: [announcement: []]
  def preload_graph(:user), do: [user: []]
end
