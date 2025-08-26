defmodule Systems.Promotion.Public do
  @moduledoc """

  """
  use Core, :public
  import Ecto.Query, warn: false

  alias Core.Repo
  alias Systems.Promotion
  alias Systems.Pool

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

  def prepare(attrs, auth_node) do
    %Promotion.Model{}
    |> Promotion.Model.changeset(:insert, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
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
  alias Frameworks.Signal
  alias Core.Repo

  def save(_promotion, changeset) do
    case Repo.update(changeset) do
      {:ok, promotion} ->
        Signal.Public.dispatch(
          {:promotion, :update_and_dispatch},
          %{promotion: promotion, changeset: changeset}
        )

        {:ok, promotion}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
