defmodule Core.Promotions do
  @moduledoc """

  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Frameworks.Signal
  alias Core.Promotions.Promotion
  alias Core.Content.{Nodes, Node}
  alias Core.Authorization
  alias Core.Pools.Submission
  alias Core.Survey.Tools
  alias Core.Studies
  alias Core.Studies.Study

  def list do
    Repo.all(Promotion)
  end

  def get!(id), do: Repo.get!(Promotion, id)
  def get(id), do: Repo.get(Promotion, id)

  def create(attrs, auth_parent, %Node{} = content_node) do
    changeset =
      %Promotion{}
      |> Promotion.changeset(:insert, attrs)
      |> Ecto.Changeset.put_assoc(:content_node, content_node)
      |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(auth_parent))

    changeset |> Repo.insert()
  end

  def update(%Promotion{} = promotion, %Changeset{} = changeset) do
    node = Nodes.get!(promotion.content_node_id)
    node_changeset = Promotion.node_changeset(node, promotion, changeset.changes)

    tool = Tools.get_by_promotion(promotion.id)
    study = Studies.get_study!(tool.study_id)
    study_changeset = Study.changeset(study, %{updated_at: NaiveDateTime.utc_now()})

    with {:ok, %{promotion: promotion} = result} <-
           Multi.new()
           |> Multi.update(:promotion, changeset)
           |> Multi.update(:content_node, node_changeset)
           |> Multi.update(:study, study_changeset)
           |> Repo.transaction() do
      Signal.Context.dispatch!(:promotion_updated, promotion)
      {:ok, result}
    end
  end

  def update(%Promotion{} = promotion, attrs) do
    changeset = Promotion.changeset(promotion, :update, attrs)
    __MODULE__.update(promotion, changeset)
  end

  def delete(%Promotion{} = promotion) do
    Repo.delete(promotion)
  end

  def ready?(%Promotion{} = promotion) do
    Nodes.get!(promotion.content_node_id).ready
  end

  def has_submission?(promotion_id, pool_id) do
    from(s in Submission, where: s.promotion_id == ^promotion_id and s.pool_id == ^pool_id)
    |> Repo.exists?()
  end
end

defimpl Core.Persister, for: Core.Promotions.Promotion do
  def save(promotion, changeset) do
    Core.Promotions.update(promotion, changeset)
  end
end
