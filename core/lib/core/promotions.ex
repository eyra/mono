defmodule Core.Promotions do
  @moduledoc """

  """
  alias Core.Repo
  alias Core.Promotions.Promotion
  alias Core.Content.{Nodes, Node}
  alias Core.Authorization

  def list do
    Repo.all(Promotion)
  end

  def get!(id), do: Repo.get!(Promotion, id)
  def get(id), do: Repo.get(Promotion, id)

  def create(attrs, auth_parent, %Node{} = content_node) do
    %Promotion{}
    |> Promotion.changeset(:insert, attrs)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(auth_parent))
    |> Repo.insert()
  end

  def update(%Promotion{} = promotion, attrs) do
    promotion
    |> Promotion.changeset(:update, attrs)
    |> update()
  end

  def update(changeset) do
    changeset
    |> Repo.update()
  end

  def delete(%Promotion{} = promotion) do
    Repo.delete(promotion)
  end

  def ready?(%Promotion{} = promotion) do
    Nodes.get!(promotion.content_node_id).ready?()
  end
end
