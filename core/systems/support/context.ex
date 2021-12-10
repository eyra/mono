defmodule Systems.Support.Context do
  @moduledoc """
  The Support context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.Support.TicketModel

  def count_open_tickets do
    from(t in TicketModel, where: is_nil(t.completed_at), select: count("*"))
    |> Repo.one()
  end

  def list_tickets(statu, preload \\ [user: [:profile, :features]])
  def list_tickets(:open, preload) do
    from(t in list_ticket_query(preload),
      where: is_nil(t.completed_at),
    )
    |> Repo.all()
  end

  def list_tickets(:closed, preload) do
    from(t in list_ticket_query(preload),
      where: not is_nil(t.completed_at),
    )
    |> Repo.all()
  end

  defp list_ticket_query(preload) do
    from(t in TicketModel,
      order_by: {:desc, :inserted_at},
      preload: ^preload
    )
  end

  def get_ticket!(id, preload \\ [user: [:profile, :features]]) do
    from(t in TicketModel,
      where: t.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def close_ticket_by_id(id) do
    from(t in TicketModel, where: t.id == ^id)
    |> Repo.update_all(set: [completed_at: DateTime.utc_now()])
  end

  def reopen_ticket_by_id(id) do
    from(t in TicketModel, where: t.id == ^id)
    |> Repo.update_all(set: [completed_at: nil])
  end

  def create_ticket(user, attrs \\ %{}) do
    %TicketModel{}
    |> TicketModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def new_ticket_changeset(attrs \\ %{type: :question}) do
    TicketModel.changeset(%TicketModel{}, attrs)
  end
end
