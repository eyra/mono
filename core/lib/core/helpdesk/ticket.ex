defmodule Core.Helpdesk.Ticket do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User

  schema "helpdesk_tickets" do
    belongs_to(:user, User)
    field(:description, :string)
    field(:title, :string)
    field(:completed_at, :utc_datetime)

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :description, :completed_at])
    |> validate_required([:title, :description])
  end
end
