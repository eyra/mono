defmodule Core.DataDonation.Task do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Core.DataDonation.Tool
  alias Core.Accounts.User

  schema "data_donation_tasks" do
    belongs_to(:data_donation_tool, Tool)
    belongs_to(:user, User)
    field(:status, Ecto.Enum, values: [:pending, :completed])

    timestamps()
  end

  @doc false
  def changeset(data_donation_task, attrs) do
    data_donation_task
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
