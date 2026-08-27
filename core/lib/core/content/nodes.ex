defmodule Core.Content.Nodes do
  @moduledoc """

  """
  alias Core.Content.Node
  alias Core.Repo

  def list do
    Repo.all(Node)
  end

  def ready?(id) when is_integer(id), do: ready?(get!(id))
  def ready?(nil), do: true
  def ready?(%Node{} = node), do: ready?(node, node.parent_id)
  def ready?(%Node{} = node, nil), do: node.ready

  def ready?(%Node{} = node, parent_id) when is_integer(parent_id), do: node.ready && ready?(get(parent_id))

  def ready?(%Node{} = node, %Node{} = parent), do: node.ready && ready?(parent)

  def parent_ready?(%Node{parent_id: nil}), do: nil
  def parent_ready?(%Node{parent_id: parent_id}), do: ready?(get!(parent_id))

  def get!(id), do: Repo.get!(Node, id)
  def get(id), do: Repo.get(Node, id)

  def create!(attrs, %Node{} = parent) do
    case create(attrs, parent) do
      {:ok, node} -> node
      _ -> nil
    end
  end

  def create(attrs, %Node{} = parent) do
    %Node{}
    |> Node.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:parent, parent)
    |> Repo.insert()
  end

  def create!(attrs) do
    case create(attrs) do
      {:ok, node} -> node
      _ -> nil
    end
  end

  def create(attrs) do
    %Node{}
    |> Node.changeset(attrs)
    |> Repo.insert()
  end

  def update(%Node{} = node, attrs) do
    node
    |> Node.changeset(attrs)
    |> update()
  end

  def update(changeset) do
    Repo.update(changeset)
  end

  def delete(%Node{} = node) do
    Repo.delete(node)
  end

  def copy(%Node{} = content_node) do
    %Node{}
    |> Node.changeset(Map.from_struct(content_node))
    |> Repo.insert!()
  end

  def copy(%Node{} = content_node, parent) do
    %Node{}
    |> Node.changeset(Map.from_struct(content_node))
    |> Ecto.Changeset.put_assoc(:parent, parent)
    |> Repo.insert!()
  end
end
