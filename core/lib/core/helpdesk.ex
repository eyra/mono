defmodule Core.Helpdesk do
  @moduledoc """
  The Helpdesk context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.Helpdesk.Ticket

  def list_open_tickets do
    from(t in Ticket,
      where: is_nil(t.completed_at),
      order_by: {:asc, :inserted_at},
      preload: :user
    )
    |> Repo.all()
  end

  def close_ticket_by_id(id) do
    from(t in Ticket, where: t.id == ^id)
    |> Repo.update_all(set: [completed_at: DateTime.utc_now()])
  end

  def create_ticket(user, attrs \\ %{}) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def new_ticket_changeset(attrs \\ %{type: :question}) do
    Ticket.changeset(%Ticket{}, attrs)
  end
end
