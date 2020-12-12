defmodule Link.Studies do
  @moduledoc """
  The Studies context.
  """

  import Ecto.Query, warn: false
  alias Link.Repo
  alias Link.Authorization

  alias Link.Studies.{Study, Participant}
  alias Link.Users.User

  @doc """
  Returns the list of studies.

  ## Examples

      iex> list_studies()
      [%Study{}, ...]

  """
  def list_studies() do
    Study |> Repo.all() |> Repo.preload(:researcher)
  end

  @doc """
  Gets a single study.

  Raises `Ecto.NoResultsError` if the Study does not exist.

  ## Examples

      iex> get_study!(123)
      %Study{}

      iex> get_study!(456)
      ** (Ecto.NoResultsError)

  """
  def get_study!(id), do: Repo.get!(Study, id)

  @doc """
  Creates a study.
  """
  def create_study(attrs, researcher) do
    %Study{}
    |> Study.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:researcher, researcher)
    |> Repo.insert()
    |> Authorization.assign_role(researcher, :researcher)
  end

  @doc """
  Updates a study.

  ## Examples

      iex> update_study(study, %{field: new_value})
      {:ok, %Study{}}

      iex> update_study(study, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_study(%Study{} = study, attrs) do
    study
    |> Study.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a study.

  ## Examples

      iex> delete_study(study)
      {:ok, %Study{}}

      iex> delete_study(study)
      {:error, %Ecto.Changeset{}}

  """
  def delete_study(%Study{} = study) do
    Repo.delete(study)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking study changes.

  ## Examples

      iex> change_study(study)
      %Ecto.Changeset{data: %Study{}}

  """
  def change_study(%Study{} = study, attrs \\ %{}) do
    Study.changeset(study, attrs)
  end

  def apply_participant(%Study{} = study, %User{} = user) do
    %Participant{status: :applied}
    |> Participant.changeset()
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def applied?(%Study{} = study, %User{} = user) do
    from(p in Participant,
      select: true,
      where:
        p.user_id == ^user.id and
          p.study_id ==
            ^study.id
    )
    |> Repo.exists?()
  end
end
