defmodule Core.Helpdesk.Ticket do
  use Ecto.Schema
  import Ecto.Changeset
  require Core.Enums.TicketTypes
  alias Core.Accounts.User

  schema "helpdesk_tickets" do
    belongs_to(:user, User)
    field(:type, Ecto.Enum, values: Core.Enums.TicketTypes.schema_values())
    field(:description, :string)
    field(:title, :string)
    field(:completed_at, :utc_datetime)

    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:type, :title, :description, :completed_at])
    |> validate_required([:title, :description])
  end
end
