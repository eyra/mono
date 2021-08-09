defmodule Core.Promotions do
  @moduledoc """

  """
  alias Core.Repo
  alias Core.Promotions.Promotion
  alias Core.Content.{Nodes, Node}
  alias Core.Authorization
  alias Core.Signals

  def list do
    Repo.all(Promotion)
  end

  def get!(id), do: Repo.get!(Promotion, id)
  def get(id), do: Repo.get(Promotion, id)

  def create(attrs, auth_parent, %Node{} = content_node) do
    changeset =
      %Promotion{}
      |> Promotion.changeset(attrs)

    result =
      changeset
      |> Ecto.Changeset.put_assoc(:content_node, content_node)
      |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(auth_parent))
      |> Repo.insert()

    with {:ok, promotion} <- result do
      {:ok, notify_when_published(promotion, changeset)}
    end
  end

  def update(%Promotion{} = promotion, attrs) do
    promotion |> Promotion.changeset(attrs) |> update()
  end

  def update(changeset) do
    with {:ok, promotion} <- Repo.update(changeset) do
      {:ok, notify_when_published(promotion, changeset)}
    end
  end

  def delete(%Promotion{} = promotion) do
    Repo.delete(promotion)
  end

  def ready?(%Promotion{} = promotion) do
    Nodes.get!(promotion.content_node_id).ready?()
  end

  defp notify_when_published(%Promotion{} = promotion, %Ecto.Changeset{} = changeset) do
    # FIXME: Add logic for published_at date > now
    if Ecto.Changeset.get_change(changeset, :published_at) do
      Signals.dispatch(:promotion_published, %{promotion: promotion})
    end

    promotion
  end
end
