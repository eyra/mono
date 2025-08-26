defmodule Systems.Notification.Public do
  @moduledoc """
  Documentation for `Notification System`.


  title
  action (optional path to view)

  """
  use Core, :public
  import Ecto.Query, warn: false
  alias Core.Repo
  alias Systems.Notification.{Box, Model, Log}
  alias Frameworks.Signal

  def notify(%Box{id: box_id} = box, %{} = notification_data) do
    with {:ok, _} <-
           %Model{}
           |> Model.changeset(notification_data)
           |> Ecto.Changeset.put_change(:box_id, box_id)
           |> Repo.insert() do
      Signal.Public.dispatch!(:new_notification, %{
        box: box,
        data: notification_data
      })

      :ok
    end
  end

  def notify(%Box{} = box, notification_data) when is_list(notification_data) do
    notify(box, Map.new(notification_data))
  end

  def notify(users, notification_data) when is_list(users) do
    Enum.reduce_while(users, {:ok, nil}, fn user, _ ->
      case notify(user, notification_data) do
        :ok -> {:cont, {:ok, nil}}
        error -> {:halt, error}
      end
    end)
  end

  def notify(%Systems.Account.User{} = user, notification_data) do
    user
    |> get_or_create_box()
    |> notify(notification_data)
  end

  def notify_users_with_role(entity, role, notification_data) do
    entity
    |> auth_module().users_with_role(role)
    |> notify(notification_data)
  end

  def list(user) do
    owned_notifications(user)
    |> where([n], n.status != :archived)
    |> select([n], %{id: n.id, title: n.title, status: n.status})
    |> order_by([n], desc: n.id)
    |> Repo.all()
  end

  def get(id) do
    Repo.get_by(Model, id: id)
  end

  def mark(notification, status) do
    notification
    |> Model.changeset(%{status: status})
    |> Repo.update()
  end

  def mark_as_notified(%{__struct__: type, id: id}, signal) do
    %{type: type, id: id, signal: signal}
    |> Log.changeset()
    |> Repo.insert!()
  end

  def marked_as_notified?(%{__struct__: type, id: id}, signal) do
    from(l in Log,
      where:
        l.item_type == ^to_string(type) and l.item_id == ^id and l.signal == ^to_string(signal)
    )
    |> Repo.exists?()
  end

  def get_or_create_box(user) do
    node_ids = auth_nodes_for_user(user)

    from(b in Box,
      where: b.auth_node_id in subquery(node_ids)
    )
    |> Repo.one()
    |> case do
      nil -> create_box!(user)
      box -> box
    end
  end

  defp create_box!(user) do
    {:ok, box} =
      %Box{}
      |> Box.changeset(%{})
      |> Ecto.Changeset.put_assoc(:auth_node, auth_module().prepare_node())
      |> Repo.insert()
      |> auth_module().assign_role(user, :owner)

    box
  end

  defp owned_notifications(user) do
    node_ids = auth_nodes_for_user(user)

    from(n in Model,
      join: b in Box,
      on: b.id == n.box_id,
      where: b.auth_node_id in subquery(node_ids)
    )
  end

  defp auth_nodes_for_user(user) do
    auth_module().query_node_ids(
      role: :owner,
      principal: user
    )
  end
end
