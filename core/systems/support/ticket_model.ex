defmodule Systems.Support.TicketModel do
  @moduledoc false
  use Ecto.Schema
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Changeset

  alias Core.Enums.TicketTypes
  alias Systems.Account.User

  require TicketTypes

  schema "helpdesk_tickets" do
    belongs_to(:user, User)
    field(:type, Ecto.Enum, values: TicketTypes.schema_values())
    field(:description, :string)
    field(:title, :string)
    field(:completed_at, :utc_datetime)

    timestamps()
  end

  def changeset(ticket, attrs) do
    cast(ticket, attrs, [:type, :title, :description, :completed_at])
  end

  def change_type(%Ecto.Changeset{} = changeset, type) when is_binary(type) do
    put_change(changeset, :type, type)
  end

  def validate(changeset) do
    validate_required(changeset, [:title, :description, :type])
  end

  def tag(ticket) do
    case ticket.type do
      :bug -> %{type: :tertiary, text: dgettext("eyra-admin", "ticket.tag.bug")}
      :tip -> %{type: :secondary, text: dgettext("eyra-admin", "ticket.tag.tip")}
      _ -> %{type: :primary, text: dgettext("eyra-admin", "ticket.tag.question")}
    end
  end
end
