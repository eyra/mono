defmodule Systems.Promotion.Public do
  @moduledoc """

  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Frameworks.Signal

  alias Systems.{
    Promotion,
    Pool
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

  def create(attrs, auth_node) do
    %Promotion.Model{}
    |> Promotion.Model.changeset(:insert, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def update(%Promotion.Model{} = _promotion, %Changeset{} = changeset) do
    result =
      Multi.new()
      |> Repo.multi_update(:promotion, changeset)
      |> Repo.transaction()

    with {:ok, %{promotion: promotion}} <- result do
      Signal.Public.dispatch!(:promotion_updated, promotion)
    end

    result
  end

  def update(%Promotion.Model{} = promotion, attrs) do
    changeset = Promotion.Model.changeset(promotion, :update, attrs)
    __MODULE__.update(promotion, changeset)
  end

  def delete(%Promotion.Model{} = promotion) do
    Repo.delete(promotion)
  end

  def copy(%Promotion.Model{title: title} = promotion, auth_node) do
    %Promotion.Model{}
    |> Promotion.Model.changeset(
      :copy,
      promotion
      |> Map.put(:title, title <> " (copy)")
      |> Map.from_struct()
    )
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def ready?(%Promotion.Model{} = promotion) do
    changeset =
      %Promotion.Model{}
      |> Promotion.Model.operational_changeset(Map.from_struct(promotion))

    changeset.valid?
  end

  def has_submission?(promotion_id, pool_id) do
    from(s in Pool.SubmissionModel,
      where: s.promotion_id == ^promotion_id and s.pool_id == ^pool_id
    )
    |> Repo.exists?()
  end
end

defimpl Core.Persister, for: Systems.Promotion.Model do
  def save(promotion, changeset) do
    case Systems.Promotion.Public.update(promotion, changeset) do
      {:ok, %{promotion: promotion}} -> {:ok, promotion}
      _ -> {:error, changeset}
    end
  end
end
