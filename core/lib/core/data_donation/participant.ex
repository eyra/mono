defmodule Core.DataDonation.Participant do
  @moduledoc """
  The schema for a donation participant.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.DataDonation.Tool
  alias Core.Accounts.User

  @primary_key false
  schema "data_donation_participants" do
    belongs_to(:tool, Tool)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(participant) do
    participant
    |> cast(%{}, [])
  end
end
