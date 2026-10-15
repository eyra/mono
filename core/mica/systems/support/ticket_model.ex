defmodule Systems.Support.TicketModel do
  use Ecto.Schema
  import Ecto.Changeset
  require Core.Enums.TicketTypes
  alias Systems.Account.User

  use Gettext, backend: CoreWeb.Gettext

  schema "helpdesk_tickets" do
    belongs_to(:user, User)
    field(:type, Ecto.Enum, values: Core.Enums.TicketTypes.schema_values())
    field(:description, :string)
    field(:title, :string)
    field(:completed_at, :utc_datetime)

    timestamps()
  end

  def changeset(ticket, attrs) do
    cast(ticket, attrs, [:type, :title, :description, :completed_at])
  end

  def change_type(%Ecto.Changeset{} = changeset, type) when is_binary(type) do
    changeset |> put_change(:type, type)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:title, :description, :type])
  end

  def tag(ticket) do
    case ticket.type do
      :bug -> %{type: :tertiary, text: dgettext("eyra-admin", "ticket.tag.bug")}
      :tip -> %{type: :secondary, text: dgettext("eyra-admin", "ticket.tag.tip")}
      _ -> %{type: :primary, text: dgettext("eyra-admin", "ticket.tag.question")}
    end
  end
end
