defmodule Systems.Promotion.Context do
  @moduledoc """

  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Frameworks.Signal
  alias Core.Content.{Nodes, Node}
  alias Core.Pools.Submission

  alias Systems.{
    Promotion
  }

  def list do
    Repo.all(Promotion.Model)
  end

  def get!(id, preload \\ []) do
    from(c in Promotion.Model,
      where: c.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get(id), do: Repo.get(Promotion, id)

  def create(attrs, auth_node, %Node{} = content_node) do
    changeset =
      %Promotion.Model{}
      |> Promotion.Model.changeset(:insert, attrs)
      |> Ecto.Changeset.put_assoc(:content_node, content_node)
      |> Ecto.Changeset.put_assoc(:auth_node, auth_node)

    changeset |> Repo.insert()
  end

  def update(%Promotion.Model{} = promotion, %Changeset{} = changeset) do
    node = Nodes.get!(promotion.content_node_id)
    node_changeset = Promotion.Model.node_changeset(node, promotion, changeset.changes)

    with {:ok, %{promotion: promotion} = result} <-
           Multi.new()
           |> Multi.update(:promotion, changeset)
           |> Multi.update(:content_node, node_changeset)
           |> Repo.transaction() do
      Signal.Context.dispatch!(:promotion_updated, promotion)
      {:ok, result}
    end
  end

  def update(%Promotion.Model{} = promotion, attrs) do
    changeset = Promotion.Model.changeset(promotion, :update, attrs)
    __MODULE__.update(promotion, changeset)
  end

  def delete(%Promotion.Model{} = promotion) do
    Repo.delete(promotion)
  end

  def copy(%Promotion.Model{title: title} = promotion, auth_node, content_node) do
    %Promotion.Model{}
    |> Promotion.Model.changeset(:copy,
        promotion
        |> Map.put(:title, title <> " (copy)")
        |> Map.from_struct()
      )
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Repo.insert!()
  end

  def ready?(%Promotion.Model{} = promotion) do
    Nodes.get!(promotion.content_node_id).ready
  end

  def has_submission?(promotion_id, pool_id) do
    from(s in Submission, where: s.promotion_id == ^promotion_id and s.pool_id == ^pool_id)
    |> Repo.exists?()
  end
end

defimpl Core.Persister, for: Systems.Promotion.Model do
  def save(promotion, changeset) do
    Systems.Promotion.Context.update(promotion, changeset)
  end
end
