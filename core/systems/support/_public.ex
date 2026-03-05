defmodule Systems.Support.Public do
  @moduledoc """
  The Support context.
  """

  use Core, :public

  import Ecto.Query, warn: false

  alias Core.Repo
  alias Systems.Support.TicketModel

  def count_open_tickets do
    Repo.one(from(t in TicketModel, where: is_nil(t.completed_at), select: count("*")))
  end

  def list_tickets(statu, preload \\ [user: [:profile, :features]])

  def list_tickets(:open, preload) do
    Repo.all(from(t in list_ticket_query(preload), where: is_nil(t.completed_at)))
  end

  def list_tickets(:closed, preload) do
    Repo.all(from(t in list_ticket_query(preload), where: not is_nil(t.completed_at)))
  end

  defp list_ticket_query(preload) do
    from(t in TicketModel,
      order_by: {:desc, :inserted_at},
      preload: ^preload
    )
  end

  def get_ticket!(id, preload \\ [user: [:profile, :features]]) do
    Repo.one!(from(t in TicketModel, where: t.id == ^id, preload: ^preload))
  end

  def close_ticket_by_id(id) do
    Repo.update_all(from(t in TicketModel, where: t.id == ^id), set: [completed_at: DateTime.utc_now()])
  end

  def reopen_ticket_by_id(id) do
    Repo.update_all(from(t in TicketModel, where: t.id == ^id), set: [completed_at: nil])
  end

  def create_ticket(user, attrs) do
    changeset = validate_ticket(user, attrs)

    if changeset.valid? do
      Repo.insert(changeset)
    else
      {:error, %{changeset | action: :insert}}
    end
  end

  def validate_ticket(user, attrs) do
    %TicketModel{}
    |> TicketModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> TicketModel.validate()
  end

  def prepare_ticket(attrs \\ %{type: :question}) do
    TicketModel.changeset(%TicketModel{}, attrs)
  end
end
